extends SceneTree
## The art registry is a build contract: missing files, stale metadata and fake
## multi-frame animations must fail before a gameplay regression is accepted.
const MANIFEST_PATH: String = "res://resources/art/manifest.json"
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, description: String) -> void:
	checks += 1
	print("PASS: " if value else "FAIL: ", description)
	if not value:
		failures.append(description)

func run() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	check(parsed is Dictionary and not parsed.is_empty(), "Art manifest exists and contains asset records")
	if not parsed is Dictionary or parsed.is_empty():
		finish()
		return
	var registry: Dictionary = parsed
	var required_ids: Array[String] = ["player", "rowan", "enemy", "house", "pine", "oak", "rock", "lamp", "crystal", "fence", "sign", "fern", "flowers", "chest", "portal", "rust_sword", "potion", "herb", "ore", "echo_shard", "sword_slash", "enemy_strike", "enemy_telegraph", "hit_spark", "grass", "stone_path", "water", "shore", "ui_panel", "ui_button", "ui_health", "firefly", "glow"]
	for id: String in required_ids:
		check(registry.has(id), "Visible type has a registered art resource: " + id)
	for id: String in registry:
		if not registry[id] is Dictionary:
			check(false, id + ": manifest entry is a dictionary")
			continue
		validate_asset(id, registry[id])
	await validate_contact_in_physics()
	await validate_idle_without_interaction()
	finish()

func validate_idle_without_interaction() -> void:
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	main.save_path = "user://art_refresh_idle_only.json"
	root.add_child(main)
	main.start_game()
	for _i: int in range(3):
		await physics_frame
	var player_position: Vector2 = main.world.player.position
	var observations: Array[Dictionary] = []
	var stopped: Array[String] = []
	var enemy: Node2D = load("res://scripts/combat/enemy.gd").new()
	enemy.position = Vector2(880, 690)
	enemy.target = main.world.player
	main.world.actors.add_child(enemy)
	enemy.health.restore(enemy.health.maximum - 1)
	var enemy_health_frames: Dictionary = {}
	var ui_frames: Dictionary = {}
	var hud_health_frames: Dictionary = {}
	for node: Node in main.world.find_children("*", "AnimatedSprite2D", true, false):
		var sprite := node as AnimatedSprite2D
		if not sprite.is_visible_in_tree():
			continue
		if not sprite.is_playing() or not sprite.sprite_frames.get_animation_loop(sprite.animation):
			stopped.append(str(sprite.get_path()))
		observations.append({"sprite": sprite, "frames": {}})
	for _i: int in range(150):
		await physics_frame
		enemy_health_frames[enemy.health_skin_texture().get_instance_id()] = true
		hud_health_frames[main.ui.health_crop.atlas.get_instance_id()] = true
		for style_entry: Dictionary in main.ui.material_styles:
			var id: int = style_entry.style.get_instance_id()
			if not ui_frames.has(id): ui_frames[id] = {}
			ui_frames[id][style_entry.style.texture.get_instance_id()] = true
		for observation: Dictionary in observations:
			var sprite: AnimatedSprite2D = observation.sprite
			observation.frames[sprite.frame] = true
	var static_objects: Array[String] = []
	for observation: Dictionary in observations:
		if observation.frames.size() < 2:
			static_objects.append(str(observation.sprite.get_path()))
	if not stopped.is_empty(): print("STOPPED_IDLE: ", stopped)
	if not static_objects.is_empty(): print("STATIC_IDLE: ", static_objects)
	check(not observations.is_empty() and stopped.is_empty(), "All persistent world sprites play their own ambient animation while no input is sent")
	check(static_objects.is_empty(), "Idle frame advances on all " + str(observations.size()) + " visible sprites without interaction")
	check(main.world.player.position == player_position and main.world.player.state == main.world.player.State.IDLE, "Idle verification leaves the player standing still")
	var terrain: TileSetAtlasSource = main.world.ground.tile_set.get_source(0)
	var paths: TileSetAtlasSource = main.world.ground.tile_set.get_source(1)
	var animated_tiles: bool = true
	for y: int in range(4):
		animated_tiles = animated_tiles and terrain.get_tile_animation_frames_count(Vector2i(0, y)) > 1 and paths.get_tile_animation_frames_count(Vector2i(0, y)) > 1
	check(animated_tiles, "Terrain and path variants retain ambient loops in the actual TileSet")
	var animated_ui: bool = true
	for id: int in ui_frames:
		animated_ui = animated_ui and ui_frames[id].size() > 1
	check(animated_ui and hud_health_frames.size() > 1, "UI panel/button states and HUD health texture animate while the player waits")
	check(enemy_health_frames.size() > 1, "Enemy health skin uses the ambient frames used by its drawing code")
	main._set_mode(main.Mode.INVENTORY_OPEN)
	var item_frames: Dictionary = {}
	for _i: int in range(90):
		await process_frame
		item_frames[main.ui.inventory_buttons[0].icon.get_instance_id()] = true
	check(item_frames.size() > 1, "Inventory item animates without selection/use while the world is paused")
	main.close_overlay()
	main.queue_free()
	await process_frame

func validate_asset(id: String, entry: Dictionary) -> void:
	check(str(entry.get("design_id", "")) != "", id + ": stable visual design declared for animation consistency")
	var metadata_valid: bool = entry.get("resource") is String and entry.get("texture") is String and entry.get("source") is String and not str(entry.get("source", "")).is_empty() and entry.get("backend") is String and entry.get("frame_size") is Array and entry.frame_size.size() == 2 and entry.get("pivot") is Array and entry.pivot.size() == 2 and entry.get("states") is Dictionary and not entry.states.is_empty() and is_integer(entry.get("columns")) and int(entry.columns) > 0
	check(metadata_valid, id + ": source, dimensions, pivot and state metadata declared")
	if not metadata_valid:
		return
	var dimensions_valid: bool = is_integer(entry.frame_size[0]) and is_integer(entry.frame_size[1]) and int(entry.frame_size[0]) > 0 and int(entry.frame_size[1]) > 0
	check(dimensions_valid, id + ": frame dimensions are positive integers")
	if not dimensions_valid:
		return
	var frame_size := Vector2i(int(entry.frame_size[0]), int(entry.frame_size[1]))
	var pivot_valid: bool = is_number(entry.pivot[0]) and is_number(entry.pivot[1]) and float(entry.pivot[0]) >= 0 and float(entry.pivot[0]) <= frame_size.x and float(entry.pivot[1]) >= 0 and float(entry.pivot[1]) <= frame_size.y
	check(pivot_valid, id + ": declared pivot lies inside frame")
	var resource: Resource = load(str(entry.resource))
	var texture: Resource = load(str(entry.texture))
	check(resource is SpriteFrames and texture is Texture2D, id + ": SpriteFrames and sheet load in Godot")
	if not resource is SpriteFrames or not texture is Texture2D:
		return
	var sprite_frames: SpriteFrames = resource
	if not id in ["sword_slash", "enemy_strike", "enemy_telegraph", "hit_spark"]:
		var idle_states: Array[String] = []
		for state: StringName in sprite_frames.get_animation_names():
			if str(state).begins_with("idle") or state == &"normal":
				idle_states.append(str(state))
		check(not idle_states.is_empty(), id + ": persistent visible object has its own idle/ambient loop")
		for state: String in idle_states:
			check(sprite_frames.get_frame_count(state) >= 2 and sprite_frames.get_animation_loop(state), id + "/" + state + ": idle plays real multiple frames without interaction")
	var sheet: Texture2D = texture
	var expected_width: int = frame_size.x * int(entry.columns)
	var sheet_valid: bool = sheet.get_width() == expected_width and sheet.get_height() % frame_size.y == 0
	check(sheet_valid, id + ": sheet dimensions match frame grid")
	check(sprite_frames.get_animation_names().size() == entry.states.size(), id + ": resource animation count matches manifest")
	var rows: int = sheet.get_height() / frame_size.y
	for state_name: String in entry.states:
		var state_record: Variant = entry.states[state_name]
		var state_texture: String = str(state_record.get("texture", entry.texture)) if state_record is Dictionary else str(entry.texture)
		var state_columns: int = int(state_record.get("columns", entry.columns)) if state_record is Dictionary else int(entry.columns)
		var state_rows: int = rows
		if state_texture != str(entry.texture):
			var alternate: Texture2D = load(state_texture)
			var alternate_valid: bool = alternate != null and state_columns > 0 and alternate.get_width() == state_columns * frame_size.x and alternate.get_height() % frame_size.y == 0
			check(alternate_valid, id + "/" + state_name + ": alternate sheet matches declared grid")
			if not alternate_valid:
				continue
			state_rows = alternate.get_height() / frame_size.y
		validate_state(id, state_name, state_record, sprite_frames, state_texture, frame_size, state_columns, state_rows)
	if id in ["sword_slash", "enemy_strike"]:
		validate_contact(id, entry, sprite_frames)
	if id == "player":
		for direction: String in ["down", "left", "right", "up"]:
			for state_name: String in ["idle", "walk", "attack", "hurt", "death"]:
				check(sprite_frames.has_animation(state_name + "_" + direction), "Player behavior has directional animation: " + state_name + "_" + direction)

func validate_contact(id: String, entry: Dictionary, sprite_frames: SpriteFrames) -> void:
	var valid: bool = is_integer(entry.get("contact_frame")) and is_number(entry.get("contact_time")) and is_number(entry.get("duration")) and sprite_frames.has_animation("play")
	check(valid, id + ": contact frame and damage time declared")
	if not valid:
		return
	var contact: int = int(entry.contact_frame)
	var fps: float = sprite_frames.get_animation_speed("play")
	var count: int = sprite_frames.get_frame_count("play")
	if fps <= 0:
		check(false, id + ": contact animation has a positive playback rate")
		return
	check(contact >= 0 and contact < count and float(entry.contact_time) >= contact / fps and float(entry.contact_time) < (contact + 1) / fps, id + ": damage time falls within visible contact frame")
	check(is_equal_approx(count / fps, float(entry.duration)) and is_equal_approx(float(entry.duration), 0.24), id + ": slash playback preserves combat duration")

func validate_contact_in_physics() -> void:
	# A real Area2D receiver and Health signal catch one-frame visual/damage drift
	# without driving AI or mutating quest state in another gameplay fixture.
	var arena := Node2D.new()
	root.add_child(arena)
	var attacker := Node2D.new()
	attacker.position = Vector2(100, 100)
	attacker.add_to_group("player")
	arena.add_child(attacker)
	var melee: Node2D = load("res://scripts/combat/melee.gd").new()
	attacker.add_child(melee)
	var receiver := Node2D.new()
	receiver.position = Vector2(100, 126)
	receiver.add_to_group("enemies")
	var health: Node = load("res://scripts/combat/health.gd").new()
	health.name = "Health"
	receiver.add_child(health)
	var hurtbox: Area2D = load("res://scripts/combat/hurtbox.gd").new()
	receiver.add_child(hurtbox)
	arena.add_child(receiver)
	var observation: Dictionary = {"hits": 0, "frame": -1, "elapsed": 0.0}
	health.damaged.connect(func(_amount: int, _direction: Vector2) -> void:
		observation.hits += 1
		var visual: AnimatedSprite2D = melee.get("visual")
		observation.frame = visual.frame if visual != null else -1
		observation.elapsed = float(melee.get("duration")) - float(melee.get("remaining"))
	)
	for _i: int in range(3):
		await physics_frame
	check(melee.begin(Vector2.DOWN, 18), "Real slash begins against a physics receiver")
	for _i: int in range(18):
		await physics_frame
	check(observation.hits == 1 and health.current == 82, "Real slash damages the overlapping target once")
	check(observation.frame == 2, "Damage signal occurs on visible slash contact frame 2")
	check(float(observation.elapsed) >= 0.084 and float(observation.elapsed) <= 0.084 + 1.0 / 60.0 + 0.0001, "Damage timing preserves 0.084 s contact with one physics tick tolerance")
	arena.queue_free()
	await process_frame

func validate_state(id: String, state_name: String, record: Variant, sprite_frames: SpriteFrames, texture_path: String, frame_size: Vector2i, columns: int, rows: int) -> void:
	var label: String = id + "/" + state_name
	var valid: bool = record is Dictionary and record.get("indices") is Array and is_integer(record.get("count")) and int(record.count) > 0 and record.indices.size() == int(record.count) and is_number(record.get("fps")) and float(record.fps) > 0 and record.get("loop") is bool
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	check(record is Dictionary and str(record.get("design_id", "")) == str(manifest[id].get("design_id", "")), label + ": state belongs to the same visual design as the existing animation set")
	check(valid and sprite_frames.has_animation(state_name), label + ": state metadata and animation exist")
	if not valid or not sprite_frames.has_animation(state_name):
		return
	var count: int = sprite_frames.get_frame_count(state_name)
	check(count == int(record.count) and is_equal_approx(sprite_frames.get_animation_speed(state_name), float(record.fps)) and sprite_frames.get_animation_loop(state_name) == bool(record.loop), label + ": frame count, FPS and loop match resource")
	var regions_valid: bool = true
	var distinct_images: Dictionary = {}
	for index: int in range(count):
		var frame: Texture2D = sprite_frames.get_frame_texture(state_name, index)
		if index >= record.indices.size() or not is_integer(record.indices[index]) or frame == null or not frame is AtlasTexture:
			regions_valid = false
			continue
		var atlas: AtlasTexture = frame
		var sheet_index: int = int(record.indices[index])
		var expected_region := Rect2((sheet_index % columns) * frame_size.x, (sheet_index / columns) * frame_size.y, frame_size.x, frame_size.y)
		regions_valid = regions_valid and sheet_index >= 0 and sheet_index < columns * rows and atlas.atlas != null and atlas.atlas.resource_path == texture_path and atlas.region == expected_region and is_equal_approx(sprite_frames.get_frame_duration(state_name, index), 1.0)
		var image: Image = frame.get_image()
		if image == null or image.is_empty():
			regions_valid = false
		else:
			distinct_images[image.get_data().hex_encode()] = true
	check(regions_valid, label + ": atlas frames match declared cells and timing")
	check(count <= 1 or distinct_images.size() > 1, label + ": multi-frame animation contains real pixel changes")

func is_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

func is_integer(value: Variant) -> bool:
	return is_number(value) and float(value) == floorf(float(value))

func finish() -> void:
	print("RESULT: ", checks - failures.size(), "/", checks, " art contract checks passed")
	quit(0 if failures.is_empty() else 1)
