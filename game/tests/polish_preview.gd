extends SceneTree
var main: Node
var failures: int = 0
var captures: Array[Dictionary] = []
var view: SubViewport
const OUT: String = "res://tests/output/polish/"

func _initialize() -> void:
	call_deferred("run")

func frames(count: int = 3) -> void:
	for i: int in range(count): await physics_frame
	await process_frame

func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	var picture: Image = view.get_texture().get_image()
	if picture.save_png(OUT+name+".png") != OK: failures += 1
	var player: CharacterBody2D = main.world.player
	captures.append({"name":name,"size":[picture.get_width(),picture.get_height()],"zoom":main.world.camera.zoom.x,"screen":main.ui.current_screen,"animation":str(player.sprite.animation),"frame":player.sprite.frame,"mouse":[root.get_mouse_position().x,root.get_mouse_position().y]})

func run() -> void:
	if DisplayServer.get_name() == "headless": quit(1); return
	DirAccess.make_dir_recursive_absolute(OUT)
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(640,360)
	view = SubViewport.new()
	view.size = Vector2i(640,360)
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	main = load("res://scenes/main/main.tscn").instantiate()
	main.save_path = "user://polish_render_only.json"
	view.add_child(main)
	main.start_game()
	await frames(5)
	await capture("world_100")
	main.change_zoom(-1)
	await frames()
	await capture("world_075")
	main.change_zoom(1)
	main.change_zoom(1)
	main.change_zoom(1)
	await frames()
	await capture("world_150")
	main.change_zoom(0)
	main.progression.gain_experience(350)
	main.open_hub()
	for i: int in range(4):
		main.select_hub_tab(i)
		await frames()
		await capture("hub_"+str(i))
	main.open_settings()
	await frames()
	await capture("settings")
	main.close_settings()
	main.close_overlay()
	for size: Vector2i in [Vector2i(1366,768),Vector2i(1920,1200),Vector2i(2560,1080)]:
		var scale: int = maxi(1,mini(size.x/640,size.y/360))
		view.size = Vector2i(ceili(float(size.x)/scale),ceili(float(size.y)/scale))
		await frames(5)
		await capture("wide_%dx%d" % [size.x,size.y])
		main.open_hub()
		main.select_hub_tab(1)
		await frames()
		await capture("stats_%dx%d" % [size.x,size.y])
		main.close_overlay()
	view.size = Vector2i(640,360)
	main.ui.hide()
	main.world.player.position = Vector2(512,488)
	Input.action_press("move_down")
	Input.action_press("move_right")
	for i: int in range(36):
		await frames(2)
		await capture("walk_%02d" % i)
	Input.action_release("move_down")
	Input.action_release("move_right")
	await frames(4)
	main.world.player.facing = "up_right"
	main.world.player.attack()
	for i: int in range(18):
		await frames(1)
		await capture("slash_%02d" % i)
	await frames(30)
	main.world.player.empowered_attack()
	for i: int in range(18):
		await frames(1)
		await capture("empowered_%02d" % i)
	main.ui.show()
	main.travel("whispering_forest")
	await frames(20)
	await capture("forest")
	var record: FileAccess = FileAccess.open("res://tests/output/polish-render-review.json",FileAccess.WRITE)
	record.store_string(JSON.stringify({"renderer":RenderingServer.get_video_adapter_name(),"failures":failures,"captures":captures},"\t"))
	main.queue_free()
	paused = false
	await process_frame
	print("POLISH_RENDER_RESULT: ",captures.size()," captures, ",failures," failures")
	quit(0 if failures == 0 else 1)
