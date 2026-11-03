extends SceneTree
## Exercise real input, physics and hurtboxes, independently of the world/save.
const CASES: Array[Array] = [
	["right", ["move_right"], Vector2(1,0)],
	["down_right", ["move_down","move_right"], Vector2(1,1)],
	["down", ["move_down"], Vector2(0,1)],
	["down_left", ["move_down","move_left"], Vector2(-1,1)],
	["left", ["move_left"], Vector2(-1,0)],
	["up_left", ["move_up","move_left"], Vector2(-1,-1)],
	["up", ["move_up"], Vector2(0,-1)],
	["up_right", ["move_up","move_right"], Vector2(1,-1)]
]
var checks: int = 0
var failures: int = 0
var arena: Node2D
var player: CharacterBody2D
var hits: Array[Dictionary] = []
var falls: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
	print("PASS: " if value else "FAIL: ", message)

func frames(count: int) -> void:
	for i: int in range(count):
		await physics_frame
	await process_frame

func release_input() -> void:
	for action: String in ["move_left","move_right","move_up","move_down","sprint"]:
		Input.action_release(action)

func run() -> void:
	load("res://scripts/core/input_setup.gd").configure()
	arena = Node2D.new()
	root.add_child(arena)
	player = load("res://scenes/player/player.tscn").instantiate()
	player.position = Vector2(300,300)
	arena.add_child(player)
	player.fallen.connect(func() -> void: falls += 1)
	await frames(2)
	for entry: Array in CASES:
		var direction: String = entry[0]
		var expected: Vector2 = entry[2].normalized()
		player.position = Vector2(300,300)
		var origin: Vector2 = player.position
		for action: String in entry[1]:
			Input.action_press(action)
		await frames(30)
		var displacement: Vector2 = player.position-origin
		check(player.facing == direction and player.sprite.animation == "walk_"+direction, direction+": held input plays its own directional walk")
		check(displacement.normalized().is_equal_approx(expected) and absf(displacement.length()-36.0) < 1.5, direction+": walk has correct bearing and normalized 72 px/s speed")
		check(player.sprite.is_playing() and is_equal_approx(player.sprite.speed_scale,1.0), direction+": real walk playback at base cadence")
		check(player.aim_vector().is_equal_approx(expected), direction+": keyboard aim agrees with the visible direction")
		release_input()
		await frames(2)
		check(player.sprite.animation == "idle_"+direction and player.velocity.is_zero_approx(), direction+": release stops and preserves directional idle")
		var idle_frames: Dictionary = {}
		var idle_origin: Vector2 = player.position
		for i: int in range(100):
			await frames(1)
			idle_frames[player.sprite.frame] = true
		check(idle_frames.size() >= 6 and player.position == idle_origin, direction+": idle animates without input or position drift")
		for action: String in entry[1]:
			Input.action_press(action)
		Input.action_press("sprint")
		origin = player.position
		await frames(30)
		check(absf(player.position.distance_to(origin)-56.0) < 2.0 and player.sprinting and is_equal_approx(player.sprite.speed_scale,1.45), direction+": normalized 112 px/s sprint and faster animation")
		release_input()
		await frames(2)
	# Turn midway through a stride: no reset to frame zero when two keys are held.
	Input.action_press("move_right")
	await frames(2)
	player.sprite.set_frame_and_progress(3,0.3)
	Input.action_press("move_up")
	await frames(1)
	check(player.sprite.animation == "walk_up_right" and player.sprite.frame == 3 and player.sprite.frame_progress >= 0.3, "Turning mid-stride preserves frame and subframe progress")
	Input.action_release("move_right")
	await frames(1)
	check(player.sprite.animation == "walk_up", "Releasing one diagonal key changes immediately to cardinal walk")
	Input.action_press("move_down")
	await frames(1)
	check(player.velocity.is_zero_approx() and player.sprite.animation == "idle_up", "Opposing input stops without losing facing")
	release_input()
	# Eight equal angular sectors also serve mouse aim and analog sticks.
	check(player._facing_from_vector(Vector2.from_angle(deg_to_rad(20))) == "right" and player._facing_from_vector(Vector2.from_angle(deg_to_rad(25))) == "down_right", "Aim sectors switch at 22.5 degrees")
	check(player._facing_from_vector(Vector2.from_angle(deg_to_rad(-25))) == "up_right" and player._facing_from_vector(Vector2.from_angle(deg_to_rad(179))) == "left", "Aim sectors wrap correctly through negative angles and 180 degrees")
	player.facing = "up_left"
	check(player._facing_from_vector(Vector2.ZERO) == "up_left", "Zero aim preserves the last direction")
	# A real wall must block X while diagonal Y continues sliding.
	var wall := StaticBody2D.new()
	wall.position = Vector2(340,300)
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(10,400)
	collision.shape = shape
	wall.add_child(collision)
	arena.add_child(wall)
	player.position = Vector2(300,300)
	Input.action_press("move_right")
	Input.action_press("move_down")
	await frames(60)
	check(player.position.x < 331 and player.position.y > 348 and player.sprite.animation == "walk_down_right", "Diagonal movement collides and slides along walls using the existing feet capsule")
	player.input_enabled = false
	var locked_position: Vector2 = player.position
	await frames(10)
	check(player.position == locked_position and player.sprite.animation == "idle_down_right", "UI input lock stops held diagonal input")
	release_input()
	player.input_enabled = true
	wall.queue_free()
	await frames(2)
	# All eight directions retain body/VFX contact and real hit timing.
	for entry: Array in CASES:
		var direction: String = entry[0]
		var expected: Vector2 = entry[2].normalized()
		player.position = Vector2(300,300)
		player.facing = direction
		player.health.restore(100)
		await frames(30)
		var target := Node2D.new()
		target.position = player.position + expected*26
		target.add_to_group("enemies")
		var health: Node = load("res://scripts/combat/health.gd").new()
		health.name = "Health"
		target.add_child(health)
		target.add_child(load("res://scripts/combat/hurtbox.gd").new())
		arena.add_child(target)
		health.damaged.connect(func(_amount: int, _bearing: Vector2) -> void:
			hits.append({"body":player.sprite.frame,"fx":player.melee.visual.frame,"elapsed":player.melee.duration-player.melee.remaining}))
		hits.clear()
		await frames(2)
		check(player.attack() and player.sprite.animation == "attack_"+direction, direction+": attack state has matching directional art")
		check(player.melee.direction.is_equal_approx(expected) and is_equal_approx(player.melee.visual.rotation,expected.angle()), direction+": slash and hitbox face the same direction")
		await frames(18)
		check(health.current == 82 and hits.size() == 1, direction+": a real receiver takes damage exactly once")
		check(hits.size() == 1 and hits[0].body == 2 and hits[0].fx == 2 and absf(hits[0].elapsed-0.1) < 0.001, direction+": body/VFX contact frame 2 matches the damage tick")
		check(player.sprite.animation == "idle_"+direction and player.sprite.speed_scale == 1.0, direction+": attack returns to matching idle")
		target.queue_free()
		player.health.damage(1,Vector2.ZERO)
		check(player.sprite.animation == "hurt_"+direction, direction+": damage selects matching hurt art")
		await frames(16)
		check(player.sprite.animation == "idle_"+direction, direction+": hurt recovers to matching idle")
		player.health.immunity = 0.0
		var previous_falls: int = falls
		player.health.damage(1000,Vector2.ZERO)
		await frames(60)
		check(player.sprite.animation == "death_"+direction and player.sprite.frame == 8 and falls == previous_falls+1, direction+": death finishes and holds final frame with one fallen event")
		check(player.sprite.modulate == Color.WHITE,direction+": death clears the temporary hurt tint on every worn layer")
		# Main respawns with a fresh actor. Reuse must not carry the old actor's
		# death_announced flag into the next independent direction case.
		player.queue_free()
		await frames(1)
		player = load("res://scenes/player/player.tscn").instantiate()
		arena.add_child(player)
		player.fallen.connect(func() -> void: falls += 1)
	await frames(2)
	release_input()
	arena.queue_free()
	await process_frame
	print("EIGHT_DIRECTION_RESULT: ", checks-failures, "/", checks, " checks passed")
	quit(0 if failures == 0 else 1)
