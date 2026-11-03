extends SceneTree
var main: Node
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func frames(count: int = 2) -> void:
	for i: int in range(count): await physics_frame
	await process_frame

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1
	print("PASS: " if value else "FAIL: ",message)

func key(code: Key, echo: bool = false) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	event.echo = echo
	root.push_input(event,true)
	await frames()
	event = event.duplicate()
	event.pressed = false
	root.push_input(event,true)
	await frames()

func mouse(button: MouseButton, at: Vector2) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button
	event.position = at
	event.pressed = true
	root.push_input(event,true)
	await frames()
	event = event.duplicate()
	event.pressed = false
	root.push_input(event,true)
	await frames()

func run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280,720)
	main = load("res://scenes/main/main.tscn").instantiate()
	main.save_path = "user://polish_controls_only.json"
	root.add_child(main)
	main.start_game()
	await frames()
	check(ProjectSettings.get_setting("display/window/size/mode") == 3 and ProjectSettings.get_setting("display/window/stretch/aspect") == "expand","Default is full-screen with an expanded world viewport")
	main.world.player.position = Vector2(548,421)
	await frames()
	check(main.world.player.interaction.get_target() == main.world.rowan,"Interaction fixture is in actual Rowan reach")
	await key(KEY_E)
	check(main.mode == main.Mode.INVENTORY_OPEN and paused and main.ui.hub_navigation.visible,"E opens the bag even next to an NPC and pauses the world")
	await key(KEY_E,true)
	check(main.mode == main.Mode.INVENTORY_OPEN,"Holding E cannot repeatedly toggle the bag")
	main.progression.gain_experience(100)
	main.world.player.health.current = 80
	main.ui.hub_tabs[1].pressed.emit()
	check(main.mode == main.Mode.CHARACTER and main.ui.character_panel.visible and paused,"Bag tab opens skill allocation in the same paused hub")
	main.ui.stat_widgets.health.button.pressed.emit()
	check(main.progression.unspent_points == 4 and main.world.player.max_hp == 120 and main.world.player.hp == 100,"Hub allocation spends a real point and preserves missing health")
	main.ui.hub_tabs[0].pressed.emit()
	main.ui.select_slot(1)
	main.ui.use_button.pressed.emit()
	check(main.world.player.hp == 120 and main.inventory.count("potion") == 2,"Bag uses an actual potion while the world is paused")
	main.ui.hub_tabs[2].pressed.emit()
	check(main.mode == main.Mode.JOURNAL and main.ui.journal_panel.visible,"Bag task tab shows real quest progress")
	main.ui.hub_tabs[3].pressed.emit()
	check(main.mode == main.Mode.HUB_SYSTEM and main.save_game(),"System tab saves actual progress without leaving the hub")
	main.ui.settings_requested.emit()
	check(main.mode == main.Mode.SETTINGS,"System tab opens image settings")
	main.close_settings()
	check(main.mode == main.Mode.HUB_SYSTEM and main.ui.hub_navigation.visible,"Settings returns to the system tab")
	main.open_settings()
	await key(KEY_E)
	check(main.mode == main.Mode.PLAYING and not paused,"E also closes settings opened inside the bag")
	main.open_hub()
	main.select_hub_tab(3)
	main.ui.load_requested.emit()
	check(main.mode == main.Mode.PLAYING and main.progression.allocated.health == 1 and main.inventory.count("potion") == 2,"Hub load restores progression and consumed inventory exactly")
	await mouse(MOUSE_BUTTON_WHEEL_UP,Vector2(430,220))
	check(main.view_zoom == 1.25 and main.world.camera.zoom == Vector2(1.25,1.25),"Mouse wheel zooms the camera, independently of the HUD")
	for i: int in range(8): await mouse(MOUSE_BUTTON_WHEEL_UP,Vector2(430,220))
	check(main.view_zoom == 2.0,"Zoom in clamps at 200 percent")
	for i: int in range(9): await mouse(MOUSE_BUTTON_WHEEL_DOWN,Vector2(430,220))
	check(main.view_zoom == 0.75 and main.world.camera.zoom.x >= 0.75,"Zoom out clamps and respects map bounds")
	await key(KEY_E)
	var zoom_before: float = main.view_zoom
	await mouse(MOUSE_BUTTON_WHEEL_UP,Vector2(320,180))
	check(main.view_zoom == zoom_before,"Wheel events over an open bag cannot zoom the world")
	await key(KEY_E)
	check(main.mode == main.Mode.PLAYING and not paused,"E closes any hub page and resumes")
	main.world.player.position = Vector2(512,488)
	Input.action_press("move_right")
	await frames(10)
	var origin: Vector2 = main.world.player.position
	for point: Vector2 in [Vector2(400,210),Vector2(450,250),Vector2(500,200)]:
		var motion := InputEventMouseMotion.new()
		motion.position = point
		motion.global_position = point
		motion.position = root.get_final_transform()*point
		motion.global_position = motion.position
		Input.parse_input_event(motion)
		await frames(3)
		check(root.get_mouse_position().distance_to(point) < 1.0 and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE,"Cursor motion is accepted while movement is held: "+str(point)+" observed "+str(root.get_mouse_position()))
	check(main.world.player.position.x > origin.x+8,"Keyboard movement continues while the cursor moves")
	var dust: int = 0
	for child: Node in main.world.actors.get_children():
		if child is AnimatedSprite2D and child.sprite_frames == load("res://resources/art/footstep_dust.tres"): dust += 1
	check(dust > 0,"Actual movement spawns the registered animated footstep dust")
	await mouse(MOUSE_BUTTON_LEFT,Vector2(450,230))
	check(main.world.player.state == main.world.player.State.ATTACK,"Left-click starts a real slash while a movement key is held")
	Input.action_release("move_right")
	await frames(30)
	dust = 0
	for child: Node in main.world.actors.get_children():
		if child is AnimatedSprite2D and child.sprite_frames == load("res://resources/art/footstep_dust.tres"): dust += 1
	check(dust == 0,"Movement particles expire without persisting in the world")
	main.world.player.position = Vector2(548,421)
	await frames()
	var energy: float = main.world.player.energy
	await mouse(MOUSE_BUTTON_RIGHT,Vector2(400,200))
	check(main.mode == main.Mode.DIALOGUE and main.world.player.energy == energy,"Right-click near Rowan interacts without spending attack energy")
	main.close_dialogue()
	main.world.player.position = Vector2(512,488)
	await frames()
	await mouse(MOUSE_BUTTON_RIGHT,Vector2(450,230))
	check(main.world.player.state == main.world.player.State.ATTACK and main.world.player.energy < energy,"Right-click away from interactables performs the empowered slash")
	await frames(30)
	for resolution: Vector2i in [Vector2i(1280,720),Vector2i(1366,768),Vector2i(1920,1200),Vector2i(2560,1080)]:
		root.size = resolution
		await frames(3)
		check(root.size == resolution,"Resize fixture reaches actual window dimensions "+str(resolution))
		main.open_hub()
		for tab: int in range(4):
			main.select_hub_tab(tab)
			await frames()
			var viewport_rect: Rect2 = root.get_visible_rect()
			var fits: bool = true
			for node: Node in main.ui.find_children("*","Control",true,false):
				if node is Label or node is Button:
					if node.is_visible_in_tree():
						var rect: Rect2 = node.get_global_rect()
						fits = fits and viewport_rect.grow(1).encloses(rect)
			check(fits,"Hub page %d remains in bounds at %s" % [tab,resolution])
		main.close_overlay()
	main.queue_free()
	await process_frame
	paused = false
	print("POLISH_CONTROLS_RESULT: ",checks-failures,"/",checks," checks passed")
	quit(0 if failures == 0 else 1)
