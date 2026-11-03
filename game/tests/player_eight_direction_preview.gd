extends SceneTree
## Real renderer and map. Only reposition between takes; motion uses real input.
const CASES: Array[Array] = [
	["down", ["move_down"]], ["down_left", ["move_down","move_left"]],
	["left", ["move_left"]], ["up_left", ["move_up","move_left"]],
	["up", ["move_up"]], ["up_right", ["move_up","move_right"]],
	["right", ["move_right"]], ["down_right", ["move_down","move_right"]]
]
const OUT: String = "res://tests/output/eight_direction_motion/"
var main: Node
var samples: Array[Dictionary] = []
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i: int in range(count):
		await physics_frame
	await process_frame

func release_input() -> void:
	for action: String in ["move_left","move_right","move_up","move_down","sprint"]:
		Input.action_release(action)

func capture(clip: String, index: int) -> void:
	await RenderingServer.frame_post_draw
	var picture: Image = root.get_texture().get_image()
	var path: String = OUT+clip+"_%02d.png" % index
	if picture.save_png(path) != OK:
		failures += 1
	var player: CharacterBody2D = main.world.player
	samples.append({"path":path,"clip":clip,"index":index,"animation":str(player.sprite.animation),"frame":player.sprite.frame,"position":[player.position.x,player.position.y],"fx_visible":player.melee.visual.visible,"fx_frame":player.melee.visual.frame})

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Eight-direction preview requires a real renderer")
		quit(1)
		return
	root.size = Vector2i(640,360)
	DirAccess.make_dir_recursive_absolute(OUT)
	main = load("res://scenes/main/main.tscn").instantiate()
	main.save_path = "user://eight_direction_preview_only.json"
	root.add_child(main)
	main.start_game()
	main.ui.hide()
	var player: CharacterBody2D = main.world.player
	# Review the death sprite without entering Main's death menu between takes.
	# The regular integration suite separately covers the actual death flow.
	for connection: Dictionary in player.fallen.get_connections():
		player.fallen.disconnect(connection.callable)
	for entry: Array in CASES:
		var direction: String = entry[0]
		release_input()
		player.position = Vector2(512,488)
		player.health.restore(100)
		await frames(3)
		for action: String in entry[1]:
			Input.action_press(action)
		for i: int in range(24):
			await frames(2)
			await capture("walk_"+direction,i)
		release_input()
		await frames(2)
		for i: int in range(8):
			await frames(12)
			await capture("idle_"+direction,i)
		if "_" in direction:
			player.attack()
			for i: int in range(18):
				await frames(1)
				await capture("attack_"+direction,i)
			player.health.immunity = 0.0
			player.health.damage(1,Vector2.ZERO)
			for i: int in range(7):
				await frames(2)
				await capture("hurt_"+direction,i)
			player.health.immunity = 0.0
			player.health.damage(1000,Vector2.ZERO)
			for i: int in range(18):
				await frames(3)
				await capture("death_"+direction,i)
			player.health.restore(100)
			await frames(2)
	release_input()
	var record: FileAccess = FileAccess.open("res://tests/output/eight-direction-motion.json",FileAccess.WRITE)
	record.store_string(JSON.stringify({"renderer":RenderingServer.get_video_adapter_name(),"walk_sample_ms":1000.0/30.0,"idle_sample_ms":200,"attack_sample_ms":1000.0/60.0,"hurt_sample_ms":1000.0/30.0,"death_sample_ms":50,"failures":failures,"samples":samples},"\t"))
	main.queue_free()
	await process_frame
	print("EIGHT_DIRECTION_RENDER: ", samples.size(), " real renderer frames; ", failures, " failures")
	quit(0 if failures == 0 else 1)
