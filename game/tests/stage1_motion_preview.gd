extends SceneTree
## Windowed only: record actual engine playback for motion/timing review.
var main: Node
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func snapshot(path: String) -> void:
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	if image.save_png(path) != OK:
		failures += 1

func run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Motion preview needs a real renderer")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute("res://tests/output/stage1_motion")
	main = load("res://scenes/main/main.tscn").instantiate()
	main.save_path = "user://stage1_render_only.json"
	root.add_child(main)
	main.start_game()
	await physics_frame
	main.ui.hide()
	# Keep the actual map, sprites, camera and physics active during sampling.
	for i: int in range(60):
		for tick: int in range(6):
			await physics_frame
		await snapshot("res://tests/output/stage1_motion/village_%02d.png" % i)
	main.world.player.facing = "right"
	main.world.player.attack()
	for i: int in range(18):
		await physics_frame
		await snapshot("res://tests/output/stage1_motion/slash_%02d.png" % i)
	main.world.player.health.immunity = 0.0
	main.world.player.health.damage(1000, Vector2.ZERO)
	for i: int in range(24):
		for tick: int in range(3):
			await physics_frame
		await snapshot("res://tests/output/stage1_motion/death_%02d.png" % i)
	var player_sprite: AnimatedSprite2D = main.world.player.sprite
	print("MOTION_CAPTURE: 60 village samples at 100ms, 18 attack samples at physics60Hz, 24 death samples at 50ms; final animation=", player_sprite.animation)
	main.queue_free()
	await process_frame
	print("MOTION_RESULT: ", failures, " failures")
	quit(0 if failures == 0 else 1)
