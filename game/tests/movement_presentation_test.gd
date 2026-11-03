extends SceneTree
var main: Node
var checks: int = 0
var failures: int = 0

class CameraProbe extends Node:
	var world: Node
	var physics_errors: Array[float] = []
	var presentation_errors: Array[float] = []
	var examples: Array = []
	func _physics_process(_delta: float) -> void:
		physics_errors.append(world.camera.global_position.distance_to(world.player.global_position))
	func _process(_delta: float) -> void:
		var vp: Viewport = world.get_viewport()
		var screen_center: Vector2 = vp.get_canvas_transform().affine_inverse() * (vp.get_visible_rect().size/2)
		var err: float = screen_center.distance_to(world.get_presented_player_position())
		presentation_errors.append(err)
		if err > 0.01 and examples.size()<3: examples.append({"target":str(world.get_presented_player_position()),"camera":str(world.camera.position),"reported_center":str(world.camera.get_screen_center_position()),"viewport_center":str(screen_center),"size":str(vp.get_visible_rect().size)})

func _initialize() -> void: call_deferred("run")
func frames(count: int = 3) -> void:
	for i: int in range(count): await physics_frame
	await process_frame
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("PASS: " if ok else "FAIL: ",message)

func run() -> void:
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280,720)
	main = load("res://scenes/main/main.tscn").instantiate()
	main.save_path = "user://movement_qa_only.json"
	root.add_child(main)
	main.start_game()
	check(Engine.max_fps == 0 and ProjectSettings.get_setting("display/window/vsync/vsync_mode") == 1,"VSync presents at the display cadence without a competing 60 FPS cap")
	check(ProjectSettings.get_setting("display/window/stretch/mode") == "canvas_items" and not ProjectSettings.get_setting("rendering/2d/snap/snap_2d_transforms_to_pixel"),"Nearest canvas rendering permits screen-pixel motion instead of whole logical-pixel jumps")
	check(is_physics_interpolation_enabled() and Engine.physics_ticks_per_second == 60,"Presentation interpolation leaves deterministic 60 Hz simulation intact")
	var world: Node = main.world
	var probe := CameraProbe.new()
	probe.world = world
	probe.process_physics_priority = 2000
	probe.process_priority = 2000
	root.add_child(probe)
	for actions: Array in [["move_up"],["move_down"],["move_left"],["move_right"],["move_up","move_left"],["move_up","move_right"],["move_down","move_left"],["move_down","move_right"]]:
		world.player.position = Vector2(512.25,500.375)
		world.snap_camera_to_player()
		for action: String in actions: Input.action_press(action)
		await frames(16)
		for action: String in actions: Input.action_release(action)
		await frames(2)
	check(probe.physics_errors.max() < 0.001,"All eight directions follow the position after movement in the same physics tick")
	if probe.presentation_errors.max() >= 0.01: print("CAMERA_PROBE: ",probe.examples)
	check(probe.presentation_errors.max() < 0.01,"Camera's actual viewport transform matches the presented player position, not only a cached property")
	world.player.position = Vector2(26,26)
	world.snap_camera_to_player()
	var half_view: Vector2 = root.get_visible_rect().size/(2*world.camera.zoom)
	check(world.camera.get_screen_center_position().is_equal_approx(half_view),"Camera still clamps to the map edges without exposing the void")
	world.player.position = Vector2(512.25,433.375)
	world.snap_camera_to_player()
	check(world.get_presented_player_position().is_equal_approx(world.player.global_position) and world.camera.position == world.player.position,"Teleport resets both presentation samples and preserves fractional positions")
	main.open_hub()
	var frozen: Vector2 = world.player.position
	await frames(12)
	check(world.player.position == frozen and world.get_presented_player_position() == frozen,"Bag pause freezes simulation and camera without residual interpolation drift")
	main.close_overlay()
	await frames()
	check(not paused and world.player.position == frozen,"Closing the hub resumes without a camera catch-up jump")
	root.remove_child(probe)
	probe.queue_free()
	main.travel("whispering_forest")
	check(main.zone == "whispering_forest","Travel remains available after the camera optimization")
	check(main.world.get_presented_player_position() == main.world.player.global_position,"A fresh area starts with presentation at its actual spawn")
	main.open_hub()
	main.select_hub_tab(3)
	check(main.save_game() and main.load_game(),"Equipment/progression/world save and load remain functional")
	check(main.world.get_presented_player_position() == main.world.player.global_position,"Loading does not blend from the previous area or the origin")
	main.queue_free()
	await process_frame
	paused = false
	print("MOVEMENT_PRESENTATION_RESULT: ",checks-failures,"/",checks," checks passed")
	quit(0 if failures == 0 else 1)
