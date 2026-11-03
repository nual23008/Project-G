extends Node2D
## Instant shape query avoids Area2D's one-physics-step overlap delay.
signal contact
const SWING_DURATION: float = 0.24
const CONTACT_TIME: float = 0.084
const CONTACT_FRAME: int = 2
const PLAYER_EFFECT: SpriteFrames = preload("res://resources/art/sword_slash.tres")
const ENEMY_EFFECT: SpriteFrames = preload("res://resources/art/enemy_strike.tres")
const EMPOWERED_EFFECT: SpriteFrames = preload("res://resources/art/empowered_slash.tres")
var damage: int = 18
var remaining: float = 0.0
var duration: float = SWING_DURATION
var direction := Vector2.DOWN
var struck: Dictionary = {}
var team: String = "player"
var hit_applied: bool = false
var visual: AnimatedSprite2D
var empowered_swing: bool = false
var weapon_contact_tip := Vector2(28,-22)

func _ready() -> void:
	visual = AnimatedSprite2D.new()
	visual.name = "SwingSprite"
	visual.sprite_frames = PLAYER_EFFECT if team == "player" else ENEMY_EFFECT
	visual.centered = false
	visual.offset = Vector2(-48,-48) if team == "player" else Vector2(-36,-36)
	# Match the new actor's hand height; the ground-space hit query stays stable.
	visual.position.y = -30 if team == "player" else -18
	visual.animation = &"play"
	visual.hide()
	add_child(visual)

func begin(aim: Vector2, amount: int, empowered: bool = false) -> bool:
	if remaining > 0.0:
		return false
	direction = aim.normalized() if aim.length_squared() > 0 else Vector2.DOWN
	if team == "player":
		# Contact crest at radius34 meets the equipped blade's projected tip.
		visual.position = weapon_contact_tip-direction*36
	damage = amount
	empowered_swing = empowered and team == "player"
	visual.sprite_frames = EMPOWERED_EFFECT if empowered_swing else PLAYER_EFFECT if team == "player" else ENEMY_EFFECT
	remaining = duration
	hit_applied = false
	struck.clear()
	visual.rotation = direction.angle()
	# A new swing direction is a discontinuous pose, not a rotation to blend
	# from the previous hidden swing when physics interpolation is enabled.
	visual.reset_physics_interpolation()
	visual.frame = 0
	visual.show()
	return true

func cancel() -> void:
	remaining = 0.0
	if is_instance_valid(visual):
		visual.hide()

func _physics_process(delta: float) -> void:
	if remaining <= 0:
		return
	remaining = maxf(0.0,remaining-delta)
	if remaining <= 0:
		visual.hide()
		return
	var elapsed: float = duration-remaining
	visual.frame = mini(visual.sprite_frames.get_frame_count(&"play")-1, int(elapsed*visual.sprite_frames.get_animation_speed(&"play")))
	if not hit_applied and elapsed >= CONTACT_TIME:
		hit_applied = true
		visual.frame = CONTACT_FRAME
		contact.emit()
		_strike()

func _strike() -> void:
	var shape := CircleShape2D.new()
	shape.radius = 17.0
	var query := PhysicsShapeQueryParameters2D.new()
	query.shape = shape
	query.transform = Transform2D(0.0, global_position + direction*17)
	query.collision_mask = 8
	query.collide_with_areas = true
	query.collide_with_bodies = false
	for result: Dictionary in get_world_2d().direct_space_state.intersect_shape(query, 16):
		var hurtbox: Area2D = result.collider
		var actor: Node2D = hurtbox.get_parent()
		if actor == get_parent() or not actor.is_in_group("enemies" if team == "player" else "player") or struck.has(actor.get_instance_id()):
			continue
		var ray := PhysicsRayQueryParameters2D.create(global_position, actor.global_position, 1)
		if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
			continue
		struck[actor.get_instance_id()] = true
		hurtbox.receive(damage, global_position)
