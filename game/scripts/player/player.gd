extends CharacterBody2D

signal fallen
enum State { IDLE, WALK, ATTACK, HURT, DEATH }
const ATTACK_DURATION: float = 0.27
const HURT_DURATION: float = 0.22
const DEATH_DURATION: float = 0.9
@export var walk_speed: float = 72.0
@export var run_speed: float = 112.0
var state: State = State.IDLE
var input_enabled: bool = true
var facing: String = "down"
var max_hp: int:
	get: return health.maximum
var hp: int:
	get: return health.current
var weapon_damage: int = 18
var cooldown: float = 0.0
var state_time: float = 0.0
var knockback := Vector2.ZERO
var death_announced: bool = false
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var interaction: Node = $Interaction
@onready var health: Node = $Health
@onready var melee: Node2D = $Melee

func _ready() -> void:
	health.damaged.connect(_on_damaged)
	melee.contact.connect(_on_swing_contact)

func _physics_process(delta: float) -> void:
	cooldown = maxf(0.0,cooldown-delta)
	state_time -= delta
	if health.current <= 0:
		if state != State.DEATH:
			state = State.DEATH
			state_time = DEATH_DURATION
		_sync_action_frame("death_"+facing, DEATH_DURATION-state_time)
		velocity = Vector2.ZERO
		if state_time <= 0 and not death_announced:
			death_announced = true
			fallen.emit()
		return
	sprite.modulate = Color(1.8,0.7,0.6) if health.immunity > 0 and fmod(health.immunity,0.16)>0.08 else Color.WHITE
	if state == State.HURT and state_time > 0:
		_sync_action_frame("hurt_"+facing, HURT_DURATION-state_time)
		velocity = knockback
		knockback = knockback.move_toward(Vector2.ZERO,delta*450)
		move_and_slide()
		return
	if state == State.ATTACK and state_time > 0:
		_sync_action_frame("attack_"+facing, ATTACK_DURATION-state_time)
		velocity = Vector2.ZERO
		return
	var direction := Vector2.ZERO
	if input_enabled:
		direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * (run_speed if Input.is_action_pressed("sprint") else walk_speed)
	state = State.WALK if direction.length_squared() > 0.0 else State.IDLE
	if state == State.WALK:
		if absf(direction.x) > absf(direction.y):
			facing = "right" if direction.x > 0.0 else "left"
		else:
			facing = "down" if direction.y > 0.0 else "up"
	move_and_slide()
	sprite.play(("walk_" if state == State.WALK else "idle_") + facing)
	sprite.speed_scale = 1.45 if state == State.WALK and Input.is_action_pressed("sprint") else 1.0

func aim_vector() -> Vector2:
	return {"left":Vector2.LEFT,"right":Vector2.RIGHT,"up":Vector2.UP,"down":Vector2.DOWN}[facing]

func attack(mouse_aim: bool = false) -> bool:
	if not input_enabled or health.current <= 0 or cooldown > 0 or state == State.HURT or weapon_damage <= 0:
		return false
	if mouse_aim:
		var aim: Vector2 = get_global_mouse_position()-global_position
		if aim.length() > 5:
			facing = ("right" if aim.x > 0 else "left") if absf(aim.x)>absf(aim.y) else ("down" if aim.y>0 else "up")
	state = State.ATTACK
	state_time = ATTACK_DURATION
	cooldown = 0.44
	_sync_action_frame("attack_"+facing, 0.0)
	melee.begin(aim_vector(),weapon_damage)
	return true

func _on_damaged(_amount: int, direction: Vector2) -> void:
	if health.current > 0:
		state = State.HURT
		state_time = HURT_DURATION
		knockback = direction*110
		_sync_action_frame("hurt_"+facing, 0.0)

func _sync_action_frame(animation_name: String, elapsed: float) -> void:
	# Movement speed never changes attack/hurt/death timing. Physics owns contact.
	sprite.speed_scale = 1.0
	sprite.animation = animation_name
	sprite.pause()
	var frames: SpriteFrames = sprite.sprite_frames
	sprite.frame = clampi(int(maxf(0.0,elapsed)*frames.get_animation_speed(animation_name)), 0, frames.get_frame_count(animation_name)-1)

func _on_swing_contact() -> void:
	if state == State.ATTACK:
		# At 60 Hz .084 seconds is sampled on the .1 s tick; hold the contact pose
		# on that tick so the body and slash match the actual damage event.
		sprite.frame = melee.CONTACT_FRAME

func stop() -> void:
	velocity = Vector2.ZERO
	if state in [State.IDLE,State.WALK]:
		state = State.IDLE
		sprite.play("idle_" + facing)
