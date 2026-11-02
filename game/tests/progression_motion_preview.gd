extends SceneTree
## Real renderer resource playback fixture; gameplay is proven by integration tests.
const EFFECT := preload("res://scripts/combat/sprite_effect.gd")
const LEVEL: SpriteFrames = preload("res://resources/art/level_up.tres")
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	if DisplayServer.get_name() == "headless":
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute("res://tests/output/progression_motion")
	var main: Node = load("res://scenes/main/main.tscn").instantiate()
	main.save_path = "user://progression_motion_only.json"
	root.add_child(main)
	main.start_game()
	main.progression.gain_experience(95)
	main.world.player.health.damage(35,Vector2.ZERO)
	for _i: int in range(20): await physics_frame
	main.world._drop_experience("scout_a",60,main.world.player.position+Vector2(48,0))
	var orb: Node2D = get_first_node_in_group("experience_orbs")
	orb.target = null
	for i: int in range(36):
		if i in [0,8,16,24]:
			main.world.player.restore_vitals(50,50)
			main.world.player.facing = "right"
			main.world.player.empowered_attack()
			EFFECT.spawn(main.world.actors, LEVEL,main.world.player.position+Vector2(0,-18),Vector2(48,48))
		if i == 28:
			orb.target = main.world.player
		for _tick: int in range(6): await physics_frame
		await RenderingServer.frame_post_draw
		var result: Error = root.get_texture().get_image().save_png("res://tests/output/progression_motion/frame_%02d.png" % i)
		if result != OK: failures += 1
	main.queue_free()
	await process_frame
	print("PROGRESSION_MOTION_RESULT: ",failures," failures; 36 renderer frames at100ms; idle orb, UI loops, empowered/play effects, final real collection")
	quit(0 if failures == 0 else 1)
