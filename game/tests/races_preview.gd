extends SceneTree
const RACES := preload("res://scripts/character/races.gd")
var view: SubViewport
var main: Node
var captures: Array[Dictionary] = []
var actors: Array[CharacterBody2D] = []
var gallery: Node2D
var failures: int = 0
const OUT := "res://tests/output/races/"
const DIRS: Array[String] = ["down","left","right","up","down_right","down_left","up_right","up_left"]
func _initialize() -> void: call_deferred("run")
func frames(n: int = 3) -> void:
	for i: int in range(n): await physics_frame
	await process_frame
func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	if view.get_texture().get_image().save_png(OUT+name+".png") != OK: failures += 1
	captures.append({"name":name,"size":[view.size.x,view.size.y]})
func find_item(id: String) -> int:
	for i: int in range(16):
		if main.inventory.slots[i].get("id","") == id: return i
	return -1
func run() -> void:
	if DisplayServer.get_name() == "headless": quit(1); return
	root.mode = Window.MODE_WINDOWED
	root.title = "Race animation review"
	root.size = Vector2i(960,540)
	DirAccess.make_dir_recursive_absolute(OUT)
	view = SubViewport.new()
	view.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	view.size = Vector2i(640,360)
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	main = load("res://scenes/main/main.tscn").instantiate()
	main.save_path = "user://races_render_only.json"
	view.add_child(main)
	main.open_race_selection()
	for id: String in RACES.IDS:
		main.ui.select_race(id)
		await frames(13)
		await capture("menu_"+id)
	for size: Vector2i in [Vector2i(854,360),Vector2i(640,400)]:
		view.size = size
		await frames()
		await capture("menu_%dx%d" % [size.x,size.y])
	view.size = Vector2i(640,360)
	for id: String in RACES.IDS:
		main.start_game(id)
		main.open_hub()
		await frames()
		await capture("bag_"+id)
		for slot: String in ["hat","shoe_right","glove_left"]: main.unequip_item(slot)
		main.equip_item(find_item("linen_tunic"),"shirt")
		main.equip_item(find_item("steel_sword"),"weapon_left")
		await frames()
		await capture("bag_mixed_"+id)
		main.close_overlay()
		await frames()
		await capture("world_"+id)
	main.queue_free()
	await process_frame
	paused = false
	# Genuine runtime actors, not menu composites: all four native rigs and
	# eight directions. Physics disabled solely to clock the authored clips.
	view.size = Vector2i(1536,576)
	gallery = Node2D.new()
	view.add_child(gallery)
	var backdrop := Polygon2D.new()
	backdrop.polygon = PackedVector2Array([Vector2.ZERO,Vector2(1536,0),Vector2(1536,576),Vector2(0,576)])
	backdrop.color = Color("282431")
	gallery.add_child(backdrop)
	for r: int in range(4):
		for col: int in range(8):
			var player: CharacterBody2D = load("res://scenes/player/player.tscn").instantiate()
			player.race_id = RACES.IDS[r]
			player.position = Vector2(col*192+96,r*144+134)
			player.scale = Vector2(2,2)
			gallery.add_child(player)
			player.set_physics_process(false)
			player.melee.set_physics_process(false)
			actors.append(player)
			var label := Label.new()
			label.position = Vector2(col*192+6,r*144)
			label.text = RACES.IDS[r]+" / "+DIRS[col]
			label.add_theme_font_size_override("font_size",12)
			gallery.add_child(label)
	for state: String in ["idle","walk","attack","hurt","death"]:
		for col: int in range(actors.size()):
			actors[col].sprite.play(state+"_"+DIRS[col%8])
			actors[col].sprite.set_frame_and_progress(0,0)
		var count: int = actors[0].sprite.sprite_frames.get_frame_count(state+"_down")
		# Sample each native cel in the renderer; common clock for repeatability.
		for index: int in range(count):
			for player: CharacterBody2D in actors:
				player.sprite.pause()
				player.sprite.set_frame_and_progress(index,0)
				player.equipment_visual.sync_pose(true)
			await capture("gallery_"+state+"_%02d" % index)
	for player: CharacterBody2D in actors:
		var empty: Dictionary = {}
		for slot: String in preload("res://scripts/inventory/inventory.gd").EQUIPMENT_SLOTS: empty[slot] = ""
		player.set_equipment(empty)
	for index: int in range(8):
		for col: int in range(actors.size()):
			actors[col].sprite.animation = "idle_"+DIRS[col%8]
			actors[col].sprite.set_frame_and_progress(index,0)
			actors[col].equipment_visual.sync_pose(true)
		await capture("gallery_base_idle_%02d" % index)
	var file := FileAccess.open("res://tests/output/races-render-review.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"renderer":RenderingServer.get_video_adapter_name(),"failures":failures,"captures":captures},"\t"))
	gallery.queue_free()
	await process_frame
	print("RACES_RENDER_RESULT: ",captures.size()," captures; ",failures," failures")
	quit(1 if failures else 0)
