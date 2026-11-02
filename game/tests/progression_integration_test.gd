extends "res://tests/phase2_test.gd"
## Physics/input integration; fights use real hitboxes and finite starter potions.

func xp_orbs(source: String) -> Array[Node2D]:
	var result: Array[Node2D] = []
	for node: Node in main.world.actors.get_children():
		if node.is_in_group("experience_orbs") and node.data.get("source_enemy", "") == source and not node.is_queued_for_deletion():
			result.append(node)
	return result

func fight_and_leave_xp(id: String) -> bool:
	var first: bool = true
	for _tick: int in range(900):
		var foe: CharacterBody2D = enemy(id)
		if foe == null:
			# Step away before the newly dropped orb reaches pickup range.
			main.world.player.position = Vector2(512,680)
			await frames(3)
			return true
		var player: CharacterBody2D = main.world.player
		if player.hp <= 0:
			return false
		if player.hp < 45:
			main.use_item(1)
		if player.cooldown <= 0.0 and player.state != player.State.HURT:
			player.position = foe.position + Vector2(24,0)
			player.facing = "left"
			await key(KEY_R if first else KEY_J)
			first = false
		await frames(1)
	return false

func cleanup() -> void:
	paused = false
	main.queue_free()
	await process_frame
	for suffix: String in ["", ".bak", ".tmp", ".bak.tmp"]:
		if FileAccess.file_exists(test_path+suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path+suffix))
	print("RESULT: ", checks-failures.size(), "/", checks, " progression integration checks passed")
	quit(0 if failures.is_empty() else 1)

func run() -> void:
	test_path = "user://progression_integration_only.json"
	main = load("res://scenes/main/main.tscn").instantiate()
	main.save_path = test_path
	root.add_child(main)
	main.start_game()
	await frames(2)
	var player: CharacterBody2D = main.world.player
	check(main.progression.level == 1 and main.progression.experience == 0 and main.progression.unspent_points == 0, "New game starts at level 1 with no XP or stat points")
	check(player.hp == 100 and player.energy == 50 and player.stamina == 100 and player.weapon_damage == 18, "Main applies the real starting vitals and combat values")
	check(main.ui.stat_widgets.size() == 7 and main.ui.xp_label.text == "XP 0 / 100", "HUD and character board show live starting progression")
	await finish_rowan()
	main.travel("whispering_forest")
	await frames(3)
	check(await fight_and_leave_xp("guardian"), "R/J input and actual melee defeat the guardian")
	var drops: Array[Node2D] = xp_orbs("guardian")
	check(drops.size() == 1 and drops[0].data.amount == 120 and main.progression.experience == 0, "Defeat drops XP on the ground instead of granting it immediately")
	if drops.size() != 1:
		await cleanup()
		return
	check(main.save_game(), "A save can retain an uncollected XP orb")
	main.return_to_menu()
	check(main.load_game(), "Continue loads a save containing the unclaimed orb")
	await frames(2)
	drops = xp_orbs("guardian")
	check(drops.size() == 1 and enemy("guardian") == null and main.progression.level == 1, "Reload restores the one pending orb without recreating its guardian or crediting XP")
	if drops.is_empty():
		await cleanup()
		return
	main.world.player.position = drops[0].position
	await frames(15)
	check(xp_orbs("guardian").is_empty() and main.progression.level == 2 and main.progression.experience == 20 and main.progression.unspent_points == 5, "Walking over 120 XP levels up once, carries 20 XP and grants exactly five points")
	await frames(20)
	check(main.progression.experience == 20 and main.progression.unspent_points == 5, "A claimed orb cannot award XP or points a second time")
	await key(KEY_C)
	player = main.world.player
	check(main.mode == main.Mode.CHARACTER and paused and main.ui.character_panel.visible, "C opens the real stat board and pauses the world")
	var old_hp: int = player.hp
	var old_energy: float = player.energy
	for stat: String in ["health","strength","energy","speed","luck"]:
		main.ui.stat_widgets[stat].button.pressed.emit()
	check(main.progression.unspent_points == 0 and main.progression.allocated.health == 1 and player.max_hp == 120 and player.hp == old_hp+20, "UI allocation spends earned points and preserves missing HP")
	check(player.weapon_damage == 20 and player.max_energy == 60 and is_equal_approx(player.energy,old_energy+10) and player.walk_speed > 72 and player.crit_chance > 0, "Strength, energy, speed and luck apply to the actual player")
	var profile: Dictionary = main.progression.snapshot()
	main.ui.allocate_stat_requested.emit("defense",100)
	check(main.progression.snapshot() == profile, "UI cannot overspend or forge an allocation")
	await key(KEY_ESCAPE)
	check(not paused and main.mode == main.Mode.PLAYING, "Esc returns from the stat board to play")
	check(await fight_and_leave_xp("scout_a"), "A regular scout can be defeated for renewable XP")
	drops = xp_orbs("scout_a")
	check(drops.size() == 1 and drops[0].data.amount == 60, "Regular scout drops one 60-XP orb")
	if drops.is_empty():
		await cleanup()
		return
	# Relocate only the pending drop to exercise the unclaimed merge case while
	# the next fight continues to use normal combat and cannot attract this orb.
	drops[0].position = Vector2(760,560)
	var pending_id: String = drops[0].object_id
	main.travel("dawn_village")
	main.travel("whispering_forest")
	await frames(3)
	check(enemy("scout_a") != null and enemy("guardian") == null and main.world.content_state.spawn_cycles.scout_a == 1, "Returning to the forest respawns the scout once and keeps the unique guardian defeated")
	check(xp_orbs("scout_a").size() == 1 and xp_orbs("scout_a")[0].object_id == pending_id, "Old pending XP survives the scout respawn cycle")
	check(await fight_and_leave_xp("scout_a"), "The respawned scout is another real combat encounter")
	drops = xp_orbs("scout_a")
	check(drops.size() == 1 and drops[0].data.amount == 120 and drops[0].object_id == pending_id, "Unclaimed XP merges without duplicate objects or overwritten reward IDs")
	var loot_count: int = 0
	for entry: Dictionary in main.world.content_state.drops:
		if str(entry.id).begins_with("scout_a_loot_"): loot_count += 1
	check(loot_count == 2, "Repeat scout cycles do not multiply one-time material loot")
	main.world.player.position = drops[0].position
	await frames(15)
	check(main.progression.level == 3 and main.progression.experience == 11 and main.progression.unspent_points == 5, "Luck bonus applies at collection and a second level grants five new points")
	main.world.player.health.restore(90)
	main.world.player.restore_vitals(27.5,44.5)
	check(main.save_game(), "Progression and fractional current vitals save together")
	main.start_game()
	check(main.progression.level == 1 and main.progression.unspent_points == 0 and main.world.player.max_hp == 100, "New Game resets the progression model and starting stats")
	main.return_to_menu()
	check(main.load_game(), "Continue reloads the progressed character after a new session")
	check(main.progression.level == 3 and main.progression.unspent_points == 5 and main.world.player.hp == 90 and main.world.player.energy == 27.5 and main.world.player.stamina == 44.5, "Load preserves level, points, derived HP and exact current resources")
	check(xp_orbs("scout_a").is_empty() and enemy("scout_a") == null and main.world.content_state.spawn_cycles.scout_a == 1, "Loading does not run the travel respawn or recreate collected XP")
	main.progression.gain_experience(9223372036854775807)
	var capped: Dictionary = main.progression.snapshot()
	main.world._drop_experience("scout_b",60,main.world.player.position)
	await frames(10)
	check(main.progression.level == 9999 and main.progression.experience == 0 and main.progression.snapshot() == capped and xp_orbs("scout_b").is_empty(), "At level 9999, collection removes the orb without extra XP or duplicate points")
	check(main.ui.xp_label.text == "XP MAX" and main.ui.level_label.text.contains("9999"), "MAX progression reaches the real HUD")
	await cleanup()
