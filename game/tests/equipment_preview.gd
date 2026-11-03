extends SceneTree
const INV := preload("res://scripts/inventory/inventory.gd")
var main: Node
var view: SubViewport
var captures: Array[Dictionary] = []
var failures: int = 0
const OUT: String = "res://tests/output/equipment/"

func _initialize() -> void:
	call_deferred("run")

func frames(count: int = 3) -> void:
	for i: int in range(count): await physics_frame
	await process_frame

func capture(name: String) -> void:
	await RenderingServer.frame_post_draw
	if view.get_texture().get_image().save_png(OUT+name+".png") != OK: failures += 1
	var player: CharacterBody2D = main.world.player
	var data: Dictionary = {"name":name,"animation":str(player.sprite.animation),"frame":player.sprite.frame,"loadout":main.inventory.equipment.duplicate(true),"damage":player.weapon_damage,"layers":{}}
	for key: String in player.equipment_visual.parts:
		var part: AnimatedSprite2D = player.equipment_visual.parts[key]
		data.layers[key] = {"visible":part.visible,"frame":part.frame,"animation":str(part.animation)}
	captures.append(data)

func find_item(id: String) -> int:
	for i: int in range(16):
		if main.inventory.slots[i].get("id","") == id: return i
	return -1

func finish(review_path: String) -> void:
	var file: FileAccess = FileAccess.open(review_path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"failures":failures,"renderer":RenderingServer.get_video_adapter_name(),"captures":captures},"\t"))
	main.queue_free()
	await process_frame
	paused = false
	print("EQUIPMENT_RENDER_RESULT: ",captures.size()," captures; ",failures," failures")
	quit(0 if failures == 0 else 1)

func run() -> void:
	if DisplayServer.get_name() == "headless": quit(1); return
	root.mode = Window.MODE_WINDOWED
	root.size = Vector2i(640,360)
	DirAccess.make_dir_recursive_absolute(OUT)
	view = SubViewport.new()
	view.size = Vector2i(640,360)
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	main = load("res://scenes/main/main.tscn").instantiate()
	main.save_path = "user://equipment_render_only.json"
	view.add_child(main)
	main.start_game()
	main.open_hub()
	await frames()
	await capture("bag_default")
	for slot: String in INV.EQUIPMENT_SLOTS: main.unequip_item(slot)
	await frames()
	await capture("bag_removed")
	for slot: String in INV.EQUIPMENT_SLOTS:
		var id: String = str(INV.STARTER[slot])
		if slot == "weapon_right": id = "steel_sword"
		if slot == "weapon_left": id = "rust_sword"
		if slot in ["shoe_left","glove_right","bracelet_left"]: continue
		if slot == "shirt": id = "linen_tunic"
		if not id.is_empty(): main.equip_item(find_item(id),slot)
	await frames()
	await capture("bag_asymmetric")
	for size: Vector2i in [Vector2i(640,400),Vector2i(854,360)]:
		view.size = size
		await frames()
		await capture("bag_wide_%dx%d" % [size.x,size.y])
	view.size = Vector2i(640,360)
	main.close_overlay()
	await frames()
	await capture("world_asymmetric")
	if OS.get_cmdline_user_args().has("--ui-only"):
		await finish("res://tests/output/equipment-ui-review.json")
		return
	# Recreate the complete outfit using real inventory transactions.
	main.open_hub()
	for slot: String in ["shoe_left","glove_right","bracelet_left"]:
		main.equip_item(find_item(str(INV.STARTER[slot])),slot)
	main.close_overlay()
	main.ui.hide()
	var cases: Array[Array] = [["down",["move_down"]],["down_left",["move_down","move_left"]],["left",["move_left"]],["up_left",["move_up","move_left"]],["up",["move_up"]],["up_right",["move_up","move_right"]],["right",["move_right"]],["down_right",["move_down","move_right"]]]
	for entry: Array in cases:
		main.world.player.position = Vector2(512,488)
		for action: String in entry[1]: Input.action_press(action)
		for i: int in range(12):
			await frames(4)
			await capture("walk_"+entry[0]+"_%02d" % i)
		for action: String in entry[1]: Input.action_release(action)
		await frames(2)
		for i: int in range(8):
			await frames(12)
			await capture("idle_"+entry[0]+"_%02d" % i)
		main.world.player.attack()
		for i: int in range(18):
			await frames(1)
			await capture("slash_"+entry[0]+"_%02d" % i)
		await frames(30)
		main.world.player.health.damage(1,Vector2.ZERO)
		for i: int in range(7):
			await frames(2)
			await capture("hurt_"+entry[0]+"_%02d" % i)
		for connection: Dictionary in main.world.player.fallen.get_connections(): main.world.player.fallen.disconnect(connection.callable)
		main.world.player.health.immunity = 0.0
		main.world.player.health.damage(1000,Vector2.ZERO)
		for i: int in range(18):
			await frames(3)
			await capture("death_"+entry[0]+"_%02d" % i)
		main._replace_world(true)
		await frames(2)
	main.open_hub()
	main.unequip_item("weapon_right")
	main.close_overlay()
	main.world.player.facing = "down_right"
	main.world.player.attack()
	for i: int in range(18):
		await frames(1)
		await capture("left_slash_%02d" % i)
	await frames(30)
	main.world.player.empowered_attack()
	for i: int in range(18):
		await frames(1)
		await capture("empowered_%02d" % i)
	await finish("res://tests/output/equipment-render-review.json")
