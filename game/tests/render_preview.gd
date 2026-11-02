extends SceneTree
## Runs through the real graphical renderer, captures screenshots, then exits.
var main: Node
var failures: int = 0

func _initialize() -> void:
	call_deferred("_run")

func capture(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var result: Error = image.save_png(path)
	print("CAPTURE: ", path, " ", image.get_size(), " result=", result)
	if result != OK:
		failures += 1
	for node: Node in main.ui.find_children("*", "Label", true, false):
		var label := node as Label
		if label.is_visible_in_tree():
			var rect: Rect2 = label.get_global_rect()
			if rect.end.x > 640.5 or rect.end.y > 360.5:
				print("FAIL: Label outside viewport: ", label.text)
				failures += 1
	if main.mode == main.Mode.DIALOGUE:
		var content_height: int = main.ui.dialogue_text.get_content_height()
		var available_height: float = main.ui.dialogue_text.size.y
		if content_height > available_height:
			print("FAIL: Dialogue overflow: ", content_height, " > ", available_height)
			failures += 1
		else:
			print("PASS: Dialogue text fits: ", content_height, " <= ", available_height)

func _run() -> void:
	main = load("res://scenes/main/main.tscn").instantiate()
	main.save_path = "user://phase1_render_only.json"
	root.add_child(main)
	await capture("res://tests/output/menu.png")
	main.start_game()
	for _i: int in range(5):
		await process_frame
	await capture("res://tests/output/village.png")
	main.world.player.position = Vector2(548, 421)
	for _i: int in range(5):
		await process_frame
	main.interact()
	main.ui.finish_typing()
	await capture("res://tests/output/dialogue.png")
	main.advance_dialogue()
	main.ui.finish_typing()
	main.advance_dialogue()
	main.ui.finish_typing()
	await capture("res://tests/output/choices.png")
	main.close_dialogue()
	main.world.player.position = Vector2(568, 236)
	for _i: int in range(5):
		await process_frame
	main.interact()
	main.ui.finish_typing()
	await capture("res://tests/output/forest_sign.png")
	main.close_dialogue()
	main.world.player.position = Vector2(680, 476)
	for _i: int in range(5):
		await process_frame
	main.interact()
	main.ui.finish_typing()
	await capture("res://tests/output/village_sign.png")
	main.close_dialogue()
	main.world.player.position = Vector2(548, 421)
	main.pause_game()
	await capture("res://tests/output/pause.png")
	main.open_settings()
	await capture("res://tests/output/settings.png")
	main.close_settings()
	main.resume_game()
	# Short real-time renderer sample; not a cross-device 60 FPS guarantee.
	var started: int = Time.get_ticks_usec()
	Input.action_press("move_right")
	for i: int in range(120):
		if i == 60:
			Input.action_release("move_right")
			Input.action_press("move_left")
		await process_frame
	Input.action_release("move_left")
	var seconds: float = float(Time.get_ticks_usec()-started) / 1000000.0
	print("REAL_RENDER_SAMPLE: 120 frames in ", snappedf(seconds, 0.001), " s; average ", snappedf(120.0/seconds, 0.1), " FPS")
	paused = false
	main.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
