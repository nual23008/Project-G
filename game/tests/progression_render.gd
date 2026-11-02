extends SceneTree
## Presentation fixtures only. The independent integration suite proves real kills.
var main: Node
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for _i: int in range(count): await process_frame

func capture(name: String) -> void:
	await frames(2)
	await RenderingServer.frame_post_draw
	var result: Error = root.get_texture().get_image().save_png("res://tests/output/progression_"+name+".png")
	if result != OK: failures += 1
	for node: Node in main.ui.find_children("*","Label",true,false):
		var label := node as Label
		if label.is_visible_in_tree():
			var rect: Rect2 = label.get_global_rect()
			if rect.position.x < -0.5 or rect.position.y < -0.5 or rect.end.x > 640.5 or rect.end.y > 360.5:
				print("FAIL: Visible label outside viewport: ", label.text)
				failures += 1
	print("CAPTURE: progression_", name, " result=", result)

func run() -> void:
	main = load("res://scenes/main/main.tscn").instantiate()
	main.save_path = "user://progression_render_only.json"
	root.add_child(main)
	main.start_game()
	await capture("starting_hud")
	main.open_character()
	await capture("starting_stats")
	main.close_overlay()
	main.progression.gain_experience(95)
	main.world.player.health.damage(35,Vector2.ZERO)
	main.world.player.restore_vitals(30,48)
	main.world._drop_experience("scout_a",60,main.world.player.position+Vector2(50,0))
	await capture("xp_drop")
	var orb: Node2D = get_first_node_in_group("experience_orbs")
	main.world.player.position = orb.position
	await frames(4)
	await capture("level_up")
	main.open_character()
	await capture("earned_points")
	for stat: String in ["health","energy","stamina","strength","defense"]:
		main.ui.stat_widgets[stat].button.pressed.emit()
	await capture("allocated")
	main.progression.gain_experience(9223372036854775807)
	main.ui.batch_buttons[3].pressed.emit()
	main.ui.stat_widgets.health.button.pressed.emit()
	await capture("level_9999")
	main.close_overlay()
	await capture("max_hud")
	# Return to an early character to view the active ability at its real scale.
	main.start_game()
	main.quests.record("npc_spoken","rowan")
	main.travel("whispering_forest")
	await frames(20)
	main.world.player.position = Vector2(534,326)
	main.world.player.facing = "left"
	main.world.player.empowered_attack()
	await frames(5)
	await capture("empowered")
	paused = false
	main.queue_free()
	await process_frame
	print("PROGRESSION_RENDER_RESULT: ",failures," failures")
	quit(0 if failures == 0 else 1)
