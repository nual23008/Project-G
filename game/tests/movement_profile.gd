extends SceneTree
## Real-renderer walk benchmark; no screenshots/readbacks inside timed frames.
var main: Node
var started: int
var first: Node
var records: Array[Array] = []
var tag: String = "baseline"
var duration: float = 6.0

class First extends Node:
	var stamp: int
	func _process(_delta: float) -> void: stamp = Time.get_ticks_usec()

class Last extends Node:
	var first: Node
	var wall_usec: int
	func _process(_delta: float) -> void: wall_usec = Time.get_ticks_usec()-first.stamp

class WalkDriver extends Node:
	var elapsed: float = 0.0
	var phase: int = -1
	func _process(delta: float) -> void:
		elapsed += delta
		var next: int = int(elapsed)%2
		if next != phase:
			Input.action_release("move_down")
			Input.action_release("move_up")
			Input.action_press("move_up" if next == 0 else "move_down")
			phase = next

func _initialize() -> void: call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless": quit(1); return
	# Use a normal window: compositor-throttled/occluded fullscreen jobs are not
	# valid frame-time measurements. The product still opens fullscreen.
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(1280,800)
	if OS.get_cmdline_user_args().has("--fullscreen-run"): root.mode = Window.MODE_FULLSCREEN
	for arg: String in OS.get_cmdline_user_args():
		if arg.begins_with("--tag="): tag = arg.trim_prefix("--tag=")
		if arg.begins_with("--fps="): Engine.max_fps = int(arg.trim_prefix("--fps="))
		if arg == "--canvas": root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	root.title = "Walk profiling / "+tag
	DisplayServer.window_move_to_foreground()
	if OS.get_cmdline_user_args().has("--wait-focus"):
		DisplayServer.window_request_attention()
		var deadline: int = Time.get_ticks_msec()+45000
		while not DisplayServer.window_is_focused() and Time.get_ticks_msec()<deadline: await process_frame
		if not DisplayServer.window_is_focused():
			print("MOVEMENT_PROFILE_FOCUS_TIMEOUT")
			quit(2)
			return
	main = load("res://scenes/main/main.tscn").instantiate()
	main.save_path = "user://performance_qa_only.json"
	root.add_child(main)
	main.start_game()
	main.world.player.position = Vector2(512,500)
	var driver := WalkDriver.new()
	driver.process_priority = -10000
	root.add_child(driver)
	first = First.new()
	first.process_priority = -20000
	root.add_child(first)
	var last := Last.new()
	last.first = first
	last.process_priority = 20000
	root.add_child(last)
	var vp: RID = root.get_viewport_rid()
	RenderingServer.viewport_set_measure_render_time(vp,true)
	if OS.get_cmdline_user_args().has("--user-visible"):
		# Give the user time to bring the real window forward before timing.
		var settle_until: int = Time.get_ticks_msec()+5000
		while Time.get_ticks_msec()<settle_until: await process_frame
	var warming: int = Time.get_ticks_usec()
	var warm_frames: int = 0
	while warm_frames<120 and Time.get_ticks_usec()-warming<2000000:
		await process_frame
		warm_frames += 1
	started = Time.get_ticks_usec()
	var previous: int = started
	while (Time.get_ticks_usec()-started)/1000000.0 < duration:
		await process_frame
		await RenderingServer.frame_post_draw
		var now: int = Time.get_ticks_usec()
		var player: CharacterBody2D = main.world.player
		records.append([(now-started)/1000000.0,(now-previous)/1000.0,
			RenderingServer.viewport_get_measured_render_time_cpu(vp),RenderingServer.viewport_get_measured_render_time_gpu(vp),
			last.wall_usec/1000.0,Performance.get_monitor(Performance.TIME_PROCESS)*1000.0,Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)*1000.0,
			Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME),Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED)/1048576.0,
			player.position.distance_to(main.world.camera.position),player.position.x,player.position.y,main.world.camera.position.x,main.world.camera.position.y,
			main.world.get_presented_player_position().distance_to(main.world.camera.global_position),
			main.world.get_presented_player_position().distance_to(main.world.camera.get_screen_center_position()),
			main.world.get_presented_player_position().x,main.world.get_presented_player_position().y,Engine.get_physics_frames()])
		previous = now
	Input.action_release("move_up")
	Input.action_release("move_down")
	var path: String = "res://tests/output/movement-"+tag+".csv"
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_csv_line(PackedStringArray(["seconds","frame_ms","render_cpu_ms","gpu_ms","process_wall_ms","process_monitor_ms","physics_monitor_ms","draw_calls","texture_mb","camera_lag_px","player_x","player_y","camera_x","camera_y","presentation_error_px","screen_center_error_px","presented_x","presented_y","physics_frame"]))
	for record: Array in records:
		var line := PackedStringArray()
		for value: Variant in record: line.append(str(value))
		file.store_csv_line(line)
	file.close()
	var meta := FileAccess.open("res://tests/output/movement-"+tag+".json",FileAccess.WRITE)
	meta.store_string(JSON.stringify({"tag":tag,"frames":records.size(),"duration":duration,"valid_foreground_run":records.size()>duration*30,"max_fps":Engine.max_fps,"refresh_hz":DisplayServer.screen_get_refresh_rate(),"root_size":[root.size.x,root.size.y],"viewport":str(root.get_visible_rect().size),"stretch":root.content_scale_mode,"interpolation":is_physics_interpolation_enabled(),"vsync":DisplayServer.window_get_vsync_mode(),"vsync_disabled_by_cli":OS.get_cmdline_args().has("--disable-vsync"),"renderer":RenderingServer.get_video_adapter_name(),"nodes":Performance.get_monitor(Performance.OBJECT_NODE_COUNT),"csv":path},"\t"))
	print("MOVEMENT_PROFILE_RESULT: ",tag," ",records.size()," frames; ",RenderingServer.get_video_adapter_name())
	main.queue_free()
	await process_frame
	quit()
