extends SceneTree
## Pure model boundaries and disk migration. Only dedicated test save paths are used.
const MODEL := preload("res://scripts/progression/progression.gd")
const SAVE := preload("res://scripts/save/save_service.gd")
const TEST_PATH: String = "user://progression_model_only.json"
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, description: String) -> void:
	checks += 1
	print("PASS: " if value else "FAIL: ", description)
	if not value:
		failures.append(description)

func same_json_data(expected: Variant, actual: Variant) -> bool:
	# JSON has one number type. Godot decodes it as float, while live models use
	# ints. Compare every field and array position exactly, allowing only this
	# numeric representation change; strings, booleans and missing keys differ.
	if (expected is int or expected is float) and (actual is int or actual is float):
		return expected == actual
	if typeof(expected) != typeof(actual):
		return false
	if expected is Dictionary:
		if expected.size() != actual.size():
			return false
		for key: Variant in expected:
			if not actual.has(key) or not same_json_data(expected[key], actual[key]):
				return false
		return true
	if expected is Array:
		if expected.size() != actual.size():
			return false
		for i: int in range(expected.size()):
			if not same_json_data(expected[i], actual[i]):
				return false
		return true
	return expected == actual

func report_difference(expected: Variant, actual: Variant, path: String = "payload") -> void:
	if expected is Dictionary and actual is Dictionary:
		for key: Variant in expected:
			if actual.has(key):
				report_difference(expected[key], actual[key], path + "." + str(key))
			else:
				print("DIFF missing: ", path, ".", key)
		for key: Variant in actual:
			if not expected.has(key): print("DIFF extra: ", path, ".", key)
	elif expected is Array and actual is Array:
		if expected.size() != actual.size(): print("DIFF size: ", path)
		for i: int in range(mini(expected.size(), actual.size())):
			report_difference(expected[i], actual[i], path + "[" + str(i) + "]")
	elif typeof(expected) != typeof(actual) or expected != actual:
		print("DIFF ", path, ": ", expected, " [", type_string(typeof(expected)), "] -> ", actual, " [", type_string(typeof(actual)), "]; equal=", expected == actual)

func run() -> void:
	test_experience_and_points()
	test_stats_and_restore()
	test_save_migration_and_world_state()
	print("RESULT: ", checks - failures.size(), "/", checks, " progression model/save checks passed")
	quit(0 if failures.is_empty() else 1)

func test_experience_and_points() -> void:
	var model: RefCounted = MODEL.new()
	var observed: Dictionary = {"changed": 0, "levels": []}
	model.changed.connect(func() -> void: observed.changed += 1)
	model.level_gained.connect(func(old_level: int, new_level: int, points: int) -> void: observed.levels.append([old_level, new_level, points]))
	check(model.level == 1 and model.experience == 0 and model.unspent_points == 0 and model.xp_required() == 100, "Level 1 starts at 0/100 XP with no free points")
	for stat: String in MODEL.STAT_KEYS:
		check(model.allocated[stat] == 0, "Initial allocation is zero: " + stat)
	var original: Dictionary = model.snapshot()
	for amount: Variant in [-1, 1.5, NAN, INF, -INF, "100", true, null, 9223372036854775808.0]:
		check(not model.gain_experience(amount).accepted and model.snapshot() == original, "Invalid XP grant is atomic: " + str(amount))
	check(observed.changed == 0 and observed.levels.is_empty(), "Rejected grants emit no change or level rewards")
	check(model.gain_experience(0).accepted and observed.changed == 0, "Zero XP is a harmless no-op")
	model.gain_experience(99)
	check(model.level == 1 and model.experience == 99 and model.unspent_points == 0, "XP below threshold grants no level or points")
	var result: Dictionary = model.gain_experience(1)
	check(model.level == 2 and model.experience == 0 and model.unspent_points == 5 and result.points_gained == 5, "Exact first threshold grants exactly five points")
	check(observed.levels == [[1, 2, 5]], "Level signal reports the actual transition once")
	check(model.allocate("health", 2) and model.allocate("strength", 3) and model.unspent_points == 0, "Allocation spends points from the conserved budget")
	original = model.snapshot()
	for pair: Array in [["health", 1], ["unknown", 1], ["health", 0], ["health", -1], ["health", 0.5], ["health", NAN]]:
		check(not model.allocate(str(pair[0]), pair[1]) and model.snapshot() == original, "Invalid or unaffordable allocation is atomic: " + str(pair))
	model.reset()
	observed.levels.clear()
	result = model.gain_experience(450)
	check(model.level == 4 and model.experience == 50 and model.unspent_points == 15, "A single grant carries XP through several increasing thresholds")
	check(result.levels_gained == 3 and result.points_gained == 15 and observed.levels == [[1, 4, 15]], "Multi-level grant emits one aggregate level event")
	check(model.xp_required(9998) == 499950070, "Quadratic requirement remains an exact integer near the level cap")
	model.reset()
	result = model.gain_experience(1666667349850)
	check(model.level == 9999 and model.experience == 0 and model.unspent_points == 49990 and model.xp_required() == 0, "Exact 64-bit cumulative XP reaches level 9999 and preserves the point cap")
	check(result.gained == 1666667349850 and result.max_level, "Cap transition reports only XP actually credited")
	original = model.snapshot()
	var before: int = int(observed.changed)
	result = model.gain_experience(9223372036854775807)
	check(result.accepted and result.gained == 0 and model.snapshot() == original and observed.changed == before, "At MAX, even INT64_MAX grants no duplicate points or overflow")
	model.reset()
	result = model.gain_experience(9223372036854775807)
	check(model.level == 9999 and model.experience == 0 and model.unspent_points == 49990 and result.gained == 1666667349850, "INT64_MAX from level 1 is consumed safely without accumulator overflow")
	model.reset()
	model.gain_experience(100.0)
	check(model.level == 2 and model.experience == 0, "Integral JSON-style XP numbers restore their integer meaning")

func test_stats_and_restore() -> void:
	var model: RefCounted = MODEL.new()
	var stats: Dictionary = model.derived_stats()
	check(stats.max_health == 100 and stats.max_energy == 50 and stats.max_stamina == 100 and is_equal_approx(stats.walk_speed, 72.0) and is_equal_approx(stats.run_speed, 112.0), "Unallocated vitals and speeds preserve the previous gameplay balance")
	check(stats.strength == 10 and stats.damage_bonus == 0 and stats.defense == 0 and stats.damage_reduction == 0.0 and stats.crit_chance == 0.0 and stats.xp_bonus == 0.0, "Unallocated combat has no random critical or extra damage")
	model.gain_experience(230)
	for stat: String in MODEL.STAT_KEYS:
		check(model.allocate(stat), "One point can be assigned to " + stat)
	stats = model.derived_stats()
	check(stats.max_health == 120 and stats.max_energy == 60 and stats.max_stamina == 110, "Health, energy and stamina each change their own maximum")
	check(is_equal_approx(stats.walk_speed, 72.0 + 108.0 / 51.0) and is_equal_approx(stats.run_speed, stats.walk_speed * 112.0 / 72.0), "Speed keeps the walk/run ratio and applies its soft curve")
	check(stats.luck == 1 and is_equal_approx(stats.crit_chance, 0.5 / 101.0) and is_equal_approx(stats.xp_bonus, stats.crit_chance), "Luck changes both critical chance and pickup XP bonus")
	check(stats.strength == 11 and stats.damage_bonus == 2 and stats.defense == 1 and is_equal_approx(stats.damage_reduction, 0.8 / 41.0), "Strength and defense expose their combat effects separately")
	var snapshot: Dictionary = model.snapshot()
	var restored: RefCounted = MODEL.new()
	var events: Dictionary = {"levels": 0}
	restored.level_gained.connect(func(_old: int, _new: int, _points: int) -> void: events.levels += 1)
	check(restored.restore(JSON.parse_string(JSON.stringify(snapshot))) and restored.snapshot() == snapshot and events.levels == 0, "JSON restore preserves allocation without rewarding another level")
	var detached: Dictionary = model.snapshot()
	detached.allocated.health = 999
	check(model.allocated.health == 1, "Snapshot data cannot mutate live allocation by reference")
	detached = snapshot.duplicate(true)
	check(restored.restore(detached), "A valid direct snapshot restores")
	detached.allocated.health = 999
	check(restored.allocated.health == 1, "Restore detaches external allocation dictionaries")
	var invalid: Array = []
	var bad: Dictionary = snapshot.duplicate(true)
	bad.level = 0
	invalid.append(bad)
	bad = snapshot.duplicate(true)
	bad.level = 10000
	invalid.append(bad)
	bad = snapshot.duplicate(true)
	bad.experience = model.xp_required()
	invalid.append(bad)
	bad = snapshot.duplicate(true)
	bad.unspent_points += 1
	invalid.append(bad)
	bad = snapshot.duplicate(true)
	bad.allocated.health = -1
	invalid.append(bad)
	bad = snapshot.duplicate(true)
	bad.allocated.speed = 0.5
	invalid.append(bad)
	bad = snapshot.duplicate(true)
	bad.allocated.extra = 0
	invalid.append(bad)
	bad = snapshot.duplicate(true)
	bad.allocated.erase("energy")
	invalid.append(bad)
	bad = snapshot.duplicate(true)
	bad.experience = NAN
	invalid.append(bad)
	bad = snapshot.duplicate(true)
	bad.unspent_points = INF
	invalid.append(bad)
	for candidate: Variant in invalid:
		check(not restored.restore(candidate) and restored.snapshot() == snapshot, "Tampered progression is rejected without changing a valid model")
	for stat: String in MODEL.STAT_KEYS:
		var cap: Dictionary = cap_snapshot()
		cap.allocated[stat] = 49990
		cap.unspent_points = 0
		check(restored.restore(cap), "Entire legal budget can be assigned to " + stat)
		stats = restored.derived_stats()
		check(stats.walk_speed < 180 and stats.run_speed < 280.000001 and stats.crit_chance < 0.5 and stats.xp_bonus < 0.5 and stats.damage_reduction < 0.8, "Soft caps remain below their limits at the largest legal allocation")
	bad = cap_snapshot()
	bad.experience = 1
	check(not restored.valid_data(bad), "A capped character cannot save residual XP")
	bad = cap_snapshot()
	bad.allocated.health = 49991
	bad.unspent_points = 0
	check(not restored.valid_data(bad), "A level-9999 character cannot exceed the 49990-point budget")

func cap_snapshot() -> Dictionary:
	var model: RefCounted = MODEL.new()
	var data: Dictionary = model.snapshot()
	data.level = 9999
	data.unspent_points = 49990
	return data

func legacy_snapshot() -> Dictionary:
	var inventory: Array = []
	for _i: int in range(16):
		inventory.append({})
	inventory[0] = {"id": "rust_sword", "count": 1}
	inventory[1] = {"id": "potion", "count": 2}
	return {
		"zone": "whispering_forest", "position": [512, 680], "hp": 73,
		"inventory": inventory,
		"quest": {"status": "active", "reward_claimed": false, "events": {"area_entered:whispering_forest": 1}},
		"flags": {"met_rowan": true},
		"areas": {"whispering_forest": {"collected": ["forest_chest"], "defeated": ["guardian"], "enemies": [{"id": "scout_a", "at": [480, 480], "hp": 19}], "drops": [{"id": "guardian_loot_1", "kind": "drop", "item": "potion", "count": 1, "at": [512, 240]}]}}
	}

func write_envelope(file_path: String, version: int, snapshot: Dictionary, checksum_valid: bool = true) -> void:
	var payload: String = JSON.stringify(snapshot)
	var file := FileAccess.open(file_path, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": version, "payload": payload, "checksum": payload.sha256_text() if checksum_valid else "invalid"}))
	file.close()

func test_save_migration_and_world_state() -> void:
	# No case uses the real journey path or deletes arbitrary user data.
	for suffix: String in ["", ".bak", ".tmp", ".bak.tmp"]:
		if FileAccess.file_exists(TEST_PATH + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH + suffix))
	var service: RefCounted = SAVE.new()
	service.path = TEST_PATH
	var legacy: Dictionary = legacy_snapshot()
	var untouched: Dictionary = legacy.duplicate(true)
	check(same_json_data({"a": [1, {"count": 2}]}, {"a": [1.0, {"count": 2.0}]}), "JSON comparison accepts only the integer/float representation difference")
	check(not same_json_data({"a": [1, 2]}, {"a": [2, 1]}) and not same_json_data({"count": 2}, {"count": 3}), "JSON comparison detects changed values and changed array order")
	check(not same_json_data({"a": {"count": 2}}, {"a": {}}) and not same_json_data({"count": 2}, {"count": 2, "extra": 0}), "JSON comparison detects missing and extra fields at any depth")
	check(not same_json_data({"count": 2}, {"count": "2"}) and not same_json_data({"count": 1}, {"count": true}), "JSON comparison never coerces strings or booleans into numbers")
	check(service.valid_snapshot(legacy), "Legacy payload validation remains compatible with old callers")
	write_envelope(TEST_PATH, 1, legacy)
	var original_raw: String = FileAccess.get_file_as_string(TEST_PATH)
	var loaded: Dictionary = service.load_game()
	check(not loaded.is_empty() and loaded.progression.level == 1 and loaded.progression.experience == 0 and loaded.progression.unspent_points == 0, "Version-1 envelope migrates to a zero-allocation level-1 character")
	check(loaded.vitals == {"energy": 50.0, "stamina": 100.0} and loaded.areas.whispering_forest.spawn_cycles == {"scout_a": 0, "scout_b": 0}, "Migration supplies initial vitals and zero spawn cycles")
	var migrated_old_fields: Dictionary = loaded.duplicate(true)
	migrated_old_fields.erase("progression")
	migrated_old_fields.erase("vitals")
	# Migration moves the existing sword to a real hand slot; restore the old
	# bag representation only for this legacy-field preservation comparison.
	check(migrated_old_fields.equipment.weapon_right == "rust_sword", "Legacy sword transfers to the right hand exactly once")
	migrated_old_fields.erase("equipment")
	migrated_old_fields.erase("race")
	migrated_old_fields.inventory[0] = {"id":"rust_sword","count":1}
	migrated_old_fields.areas.whispering_forest.erase("spawn_cycles")
	if not same_json_data(legacy, migrated_old_fields):
		report_difference(legacy, migrated_old_fields, "migration")
	check(same_json_data(legacy, migrated_old_fields) and legacy == untouched, "Migration preserves every old gameplay field and the caller's source dictionary")
	check(FileAccess.get_file_as_string(TEST_PATH) == original_raw and not FileAccess.file_exists(TEST_PATH + ".bak"), "Loading or probing a v1 save never rewrites it or rotates backup")
	check(service.has_save() and FileAccess.get_file_as_string(TEST_PATH) == original_raw, "Continue availability checks are read-only during migration")
	var invalid: Dictionary = legacy.duplicate(true)
	invalid.hp = 101
	write_envelope(TEST_PATH + ".tmp", 1, invalid)
	check(service.read_valid(TEST_PATH + ".tmp").is_empty(), "A checksummed v1 payload must pass its original 100-HP schema before migration")
	write_envelope(TEST_PATH + ".tmp", 1, legacy, false)
	check(service.read_valid(TEST_PATH + ".tmp").is_empty(), "V1 checksum is verified before migration")
	var model: RefCounted = MODEL.new()
	model.gain_experience(230)
	model.allocate("health", 2)
	model.allocate("energy", 1)
	model.allocate("stamina", 1)
	loaded.progression = model.snapshot()
	loaded.hp = 137
	loaded.vitals = {"energy": 37.25, "stamina": 65.5}
	loaded.areas.whispering_forest.spawn_cycles = {"scout_a": 3, "scout_b": 7}
	loaded.areas.whispering_forest.drops.append({"id": "scout_a_c2_xp", "kind": "experience", "amount": 60, "source_enemy": "scout_a", "at": [478, 482]})
	check(service.valid_snapshot(loaded) and service.save_game(loaded), "V2 accepts derived HP, fractional current vitals, cycle IDs and an uncollected XP orb")
	var envelope: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TEST_PATH))
	check(envelope.version == 4 and FileAccess.get_file_as_string(TEST_PATH + ".bak") == original_raw, "First explicit save writes v4 while preserving a valid v1 backup")
	var restored: Dictionary = service.load_game()
	if not same_json_data(loaded, restored):
		report_difference(loaded, restored, "roundtrip")
	check(same_json_data(loaded, restored), "V2 round trip preserves XP/points, vitals, live enemy HP, collected objects and pending drops")
	var raw_v2: String = FileAccess.get_file_as_string(TEST_PATH)
	invalid = loaded.duplicate(true)
	invalid.hp = 141
	check(not service.save_game(invalid) and FileAccess.get_file_as_string(TEST_PATH) == raw_v2, "HP above the allocated maximum cannot overwrite a valid save")
	invalid = loaded.duplicate(true)
	invalid.vitals.energy = 61
	check(not service.valid_snapshot(invalid), "Energy above the allocated maximum is invalid")
	invalid = loaded.duplicate(true)
	invalid.vitals.stamina = NAN
	check(not service.valid_snapshot(invalid), "Non-finite current stamina is rejected")
	invalid = loaded.duplicate(true)
	invalid.progression.unspent_points += 1
	check(not service.valid_snapshot(invalid), "A forged stat point invalidates the entire v2 save")
	invalid = loaded.duplicate(true)
	invalid.erase("vitals")
	check(not service.valid_snapshot(invalid), "A partial v2 payload is not treated as a legacy save")
	for bad_cycle: Variant in [-1, 1.5, 1000000000001, INF, "1"]:
		invalid = loaded.duplicate(true)
		invalid.areas.whispering_forest.spawn_cycles.scout_a = bad_cycle
		check(not service.valid_snapshot(invalid), "Invalid respawn counter is rejected: " + str(bad_cycle))
	invalid = loaded.duplicate(true)
	invalid.areas.whispering_forest.spawn_cycles.guardian = 1
	check(not service.valid_snapshot(invalid), "Guardian has no repeatable spawn-cycle counter")
	for amount: Variant in [0, -1, 1.5, 2000000000001, INF, "60"]:
		invalid = loaded.duplicate(true)
		invalid.areas.whispering_forest.drops[1].amount = amount
		check(not service.valid_snapshot(invalid), "Invalid XP orb amount is rejected: " + str(amount))
	invalid = loaded.duplicate(true)
	invalid.areas.whispering_forest.drops.append(invalid.areas.whispering_forest.drops[1].duplicate(true))
	check(not service.valid_snapshot(invalid), "Duplicate pending orb IDs are rejected")
	invalid = loaded.duplicate(true)
	invalid.areas.whispering_forest.collected.append("scout_a_c2_xp")
	check(not service.valid_snapshot(invalid), "An orb cannot be both collected and pending")
	invalid = loaded.duplicate(true)
	invalid.areas.whispering_forest.drops[1].item = "ore"
	check(not service.valid_snapshot(invalid), "An XP drop cannot masquerade as inventory loot")
	invalid = loaded.duplicate(true)
	invalid.areas.whispering_forest.drops[1].source_enemy = "unknown_enemy"
	check(not service.valid_snapshot(invalid), "Optional XP orb merge ownership is constrained to existing enemy types")
	invalid = loaded.duplicate(true)
	invalid.areas.whispering_forest.drops[1].amount = 2000000000000
	invalid.areas.whispering_forest.spawn_cycles.scout_a = 1000000000000
	check(service.valid_snapshot(invalid), "Bounded merged XP and cycle limits still support the entire level-9999 curve")
	invalid = loaded.duplicate(true)
	invalid.areas.whispering_forest.erase("spawn_cycles")
	check(service.valid_snapshot(invalid), "Missing optional v2 spawn cycles defaults to an empty dictionary")
	check(service.save_game(loaded), "Another explicit save can rotate the previous v2 into backup")
	var backup_raw: String = FileAccess.get_file_as_string(TEST_PATH + ".bak")
	var file := FileAccess.open(TEST_PATH, FileAccess.WRITE)
	file.store_string("{corrupt primary")
	file.close()
	check(same_json_data(loaded, service.load_game()) and service.recovered_backup, "A corrupt primary recovers the complete v2 backup")
	check(service.save_game(loaded) and FileAccess.get_file_as_string(TEST_PATH + ".bak") == backup_raw, "Saving over a corrupt primary preserves the verified backup")
	# The envelope checksum covers payload bytes, so changing version 2 to 1
	# alone cannot invalidate it. Reserved fields must make the old schema fail.
	for field: String in ["progression", "vitals"]:
		invalid = legacy.duplicate(true)
		invalid[field] = loaded[field].duplicate(true)
		write_envelope(TEST_PATH + ".tmp", 1, invalid)
		check(service.read_valid(TEST_PATH + ".tmp").is_empty(), "V1 rejects the v2-reserved field before migration: " + field)
	invalid = legacy.duplicate(true)
	invalid.areas.whispering_forest.spawn_cycles = {"scout_a": 7}
	write_envelope(TEST_PATH + ".tmp", 1, invalid)
	check(service.read_valid(TEST_PATH + ".tmp").is_empty(), "V1 rejects v2 spawn cycles instead of resetting them during migration")
	var downgraded: Dictionary = loaded.duplicate(true)
	downgraded.erase("race")
	downgraded.erase("equipment") # Keep this a genuine v2-to-v1 downgrade fixture.
	downgraded.hp = 73
	downgraded.areas.whispering_forest.drops.remove_at(1)
	downgraded.areas.whispering_forest.erase("spawn_cycles")
	write_envelope(TEST_PATH, 1, downgraded)
	write_envelope(TEST_PATH + ".bak", 4, loaded)
	var downgraded_raw: String = FileAccess.get_file_as_string(TEST_PATH)
	check(service.read_valid(TEST_PATH).is_empty(), "A checksummed v2 profile disguised as v1 is rejected even with legacy-compatible HP and drops")
	check(same_json_data(loaded, service.load_game()) and service.recovered_backup, "Version downgrade falls back to the valid v2 backup without losing XP, points or world state")
	check(FileAccess.get_file_as_string(TEST_PATH) == downgraded_raw, "Rejected downgrade and backup recovery never rewrite the source file")
	write_envelope(TEST_PATH + ".tmp", 1, legacy)
	write_envelope(TEST_PATH, 2, loaded, false)
	var legacy_file := FileAccess.open(TEST_PATH + ".bak", FileAccess.WRITE)
	legacy_file.store_string(original_raw)
	legacy_file.close()
	restored = service.load_game()
	check(service.recovered_backup and restored.hp == 73 and restored.progression.level == 1, "A v1 backup remains recoverable after a corrupt v2 primary")
	for suffix: String in ["", ".bak", ".tmp", ".bak.tmp"]:
		if FileAccess.file_exists(TEST_PATH + suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(TEST_PATH + suffix))
