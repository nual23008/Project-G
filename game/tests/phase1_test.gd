extends SceneTree
## Integration checks against real scenes, physics and synthetic input.
var failures: Array[String] = []
var checks: int = 0
var main: Node

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures.append(description)
		print("FAIL: ", description)
	else:
		print("PASS: ", description)

func frames(count: int) -> void:
	for _i: int in range(count):
		await physics_frame
	await process_frame

func walk(actions: Array[String], count: int) -> void:
	for action: String in actions:
		Input.action_press(action)
	await frames(count)
	for action: String in actions:
		Input.action_release(action)
	await frames(2)

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	Input.parse_input_event(event)
	await frames(1)
	event = event.duplicate()
	event.pressed = false
	Input.parse_input_event(event)
	await frames(1)

func click(point: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = point
	motion.global_position = point
	Input.parse_input_event(motion)
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.position = point
	event.global_position = point
	event.pressed = true
	event.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(event)
	await frames(1)
	event = event.duplicate()
	event.pressed = false
	event.button_mask = 0
	Input.parse_input_event(event)
	await frames(1)

func _run() -> void:
	main = load("res://scenes/main/main.tscn").instantiate()
	main.save_path = "user://phase1_automated_only.json"
	root.add_child(main)
	await frames(3)
	check(main.mode == main.Mode.MENU and paused, "Boot reaches menu and freezes world")
	check(main.ui.new_button.has_focus(), "New game gets keyboard focus")
	# Exercise actual Button input rather than calling start_game for the first boot.
	await key(KEY_ENTER)
	check(main.mode == main.Mode.PLAYING and not paused, "Enter on menu starts playable game")
	check(main.world.ground.get_used_cells().size() == 3072, "64x48 populated tile map")
	check(main.world.obstacle_count > 150, "Forest and village obstacles instantiated")
	check(main.world.player.hp == 100, "Player starts with full HP")
	var player: CharacterBody2D = main.world.player
	var start := Vector2(512, 464)
	var directions: Array[Array] = [["move_right"], ["move_left"], ["move_up"], ["move_down"], ["move_right", "move_up"], ["move_right", "move_down"], ["move_left", "move_up"], ["move_left", "move_down"]]
	var distances: Array[float] = []
	for actions: Array in directions:
		player.position = start
		await frames(2)
		var typed: Array[String] = []
		typed.assign(actions)
		await walk(typed, 30)
		var distance: float = start.distance_to(player.position)
		distances.append(distance)
		check(distance > 32.0 and distance < 40.0, "Eight-way movement distance: " + str(actions))
	check(absf(distances[0]-distances[4]) < 1.8, "Diagonal speed normalized")
	player.position = start
	await frames(2)
	await walk(["move_right", "sprint"], 30)
	check(player.position.x-start.x > distances[0]*1.4, "Shift sprint increases speed")
	check(player.sprite.animation == "idle_right", "Walk returns to directional idle")
	check(main.world.camera.position == player.position.round(), "Camera follows rounded player position")
	# Independent static obstacles: house, tree, NPC, fence, water and world bounds.
	player.position = Vector2(736, 386)
	await frames(2)
	await walk(["move_up"], 60)
	check(player.position.y > 374 and player.position.y < 379, "House wall blocks player")
	player.position = Vector2(656, 505)
	await frames(2)
	await walk(["move_up"], 45)
	check(player.position.y > 486 and player.position.y < 492, "Tree trunk blocks player")
	player.position = Vector2(548, 418)
	await frames(2)
	await walk(["move_up"], 45)
	check(player.position.y > 401 and player.position.y < 406, "Rowan body blocks player")
	player.position = Vector2(520, 180)
	await frames(2)
	await walk(["move_up"], 45)
	check(player.position.y > 164, "Closed north fence blocks forest access")
	player.position = Vector2(810, 466)
	await frames(2)
	await walk(["move_down"], 60)
	check(player.position.y < 478 and player.position.y > 470, "Water tiles have collision")
	player.position = Vector2(200, 24)
	await frames(2)
	await walk(["move_up"], 45)
	check(player.position.y >= 20.0, "World edge is bounded even outside tree trunks")
	# Proximity and line-of-sight: interactables beyond reach or hidden cannot start.
	player.position = start
	await frames(2)
	await key(KEY_F)
	check(main.mode == main.Mode.PLAYING, "F away from NPC does not start dialogue")
	player.position = Vector2(548, 421)
	await frames(2)
	check(player.interaction.find_nearest() == main.world.rowan, "Nearest visible interactable is Rowan")
	check(main.ui.prompt.text.contains("Rowan"), "Interaction HUD prompt reflects target")
	await key(KEY_F)
	check(main.mode == main.Mode.DIALOGUE and paused, "F opens dialogue and freezes gameplay")
	check(main.ui.speaker_label.text == "Trưởng làng Rowan", "Vietnamese speaker displays intact")
	check(main.ui.typing, "Typewriter starts on line open")
	await key(KEY_ENTER)
	check(main.mode == main.Mode.DIALOGUE and not main.ui.typing and main.dialogue.current_node == "greeting", "Enter skips typewriter without closing dialogue")
	# Reopen to independently verify E's skip behavior below.
	main.close_dialogue()
	await key(KEY_F)
	var held_position: Vector2 = player.position
	await walk(["move_right", "sprint"], 12)
	check(player.position == held_position, "Dialogue blocks held movement and sprint")
	await key(KEY_F)
	check(not main.ui.typing and main.dialogue.current_node == "greeting", "F skips text without skipping line")
	await key(KEY_F)
	check(main.dialogue.current_node == "name", "F advances to next dialogue line")
	main.ui.finish_typing()
	main.advance_dialogue()
	main.ui.finish_typing()
	check(main.dialogue.current_node == "questions" and main.ui.choice_box.get_child_count() == 3, "Data-defined branch exposes three choices")
	# Keyboard Enter activates the focused option, including its captured index.
	await key(KEY_ENTER)
	check(main.dialogue.current_node == "crystal", "Keyboard choice follows crystal branch")
	main.ui.finish_typing()
	main.advance_dialogue()
	main.ui.finish_typing()
	main.advance_dialogue()
	main.ui.finish_typing()
	(main.ui.choice_box.get_child(1) as Button).pressed.emit()
	check(main.dialogue.current_node == "village", "Second choice follows village branch")
	main.ui.finish_typing()
	main.advance_dialogue()
	main.ui.finish_typing()
	main.advance_dialogue()
	main.ui.finish_typing()
	(main.ui.choice_box.get_child(2) as Button).pressed.emit()
	check(main.dialogue.current_node == "farewell", "Third choice reaches farewell")
	main.ui.finish_typing()
	main.advance_dialogue()
	check(main.mode == main.Mode.PLAYING and main.met_rowan and not paused, "Completed talk returns control and updates orientation")
	await key(KEY_F)
	await key(KEY_ESCAPE)
	check(main.mode == main.Mode.PLAYING and not main.dialogue.active, "Esc cancels dialogue safely")
	await key(KEY_ESCAPE)
	check(main.mode == main.Mode.PAUSED and paused, "Esc opens pause menu")
	held_position = player.position
	await walk(["move_down"], 12)
	check(player.position == held_position, "Pause menu prevents movement")
	main.open_settings()
	check(main.mode == main.Mode.SETTINGS, "Settings opens from pause")
	main.ui.effects_check.button_pressed = false
	check(not main.world.get_node("Atmosphere").visible, "Effects setting changes actual world rendering")
	await key(KEY_ESCAPE)
	check(main.mode == main.Mode.PAUSED, "Settings returns to pause context")
	await key(KEY_ESCAPE)
	check(main.mode == main.Mode.PLAYING, "Esc resumes game")
	main.pause_game()
	main.ui.menu_requested.emit()
	await frames(2)
	check(main.mode == main.Mode.MENU and not main.dialogue.active, "Pause menu returns to main menu")
	main.start_game()
	await frames(2)
	check(main.world.player.position == start and not main.met_rowan, "New game resets spawn and session flags")
	check(not main.world.get_node("Atmosphere").visible, "Visual preference survives session restart")
	# Walk a complete route using physical WASD key events, no teleport.
	var held_key := InputEventKey.new()
	held_key.physical_keycode = KEY_W
	held_key.keycode = KEY_W
	held_key.pressed = true
	Input.parse_input_event(held_key)
	await frames(34)
	held_key.pressed = false
	Input.parse_input_event(held_key)
	held_key = InputEventKey.new()
	held_key.physical_keycode = KEY_D
	held_key.keycode = KEY_D
	held_key.pressed = true
	Input.parse_input_event(held_key)
	await frames(30)
	held_key.pressed = false
	Input.parse_input_event(held_key)
	await frames(2)
	check(main.world.player.position.distance_to(main.world.rowan.position) < 42.0, "Physical W and D reach Rowan from actual spawn")
	await key(KEY_F)
	check(main.mode == main.Mode.DIALOGUE, "Spawn-to-Rowan journey opens dialogue with F")
	main.close_dialogue()
	main.return_to_menu()
	main.open_settings()
	main.close_settings()
	check(main.mode == main.Mode.MENU, "Settings restores main menu context")
	await click(main.ui.new_button.get_global_rect().get_center())
	check(main.mode == main.Mode.PLAYING, "Mouse click on New Game starts gameplay")
	# Validate all dialogue links and starts to avoid data-only dead ends.
	for id: String in main.dialogue.database:
		var entry: Dictionary = main.dialogue.database[id]
		check(entry.nodes.has(entry.start), "Dialogue start exists: " + id)
		for node_id: String in entry.nodes:
			var node: Dictionary = entry.nodes[node_id]
			var valid: bool = str(node.get("next", "")).is_empty() or entry.nodes.has(node.next)
			for choice: Dictionary in node.get("choices", []):
				valid = valid and entry.nodes.has(choice.next)
			check(valid, "Dialogue edges valid: " + id + "/" + node_id)
	print("RESULT: ", checks-failures.size(), "/", checks, " checks passed")
	paused = false
	main.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
