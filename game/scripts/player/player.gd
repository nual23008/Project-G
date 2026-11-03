extends CharacterBody2D
const FOOTSTEP_ART: SpriteFrames = preload("res://resources/art/footstep_dust.tres")
const FOOTSTEP_EFFECT := preload("res://scripts/combat/sprite_effect.gd")
var stride_distance: float = 0.0
var step_left: bool = false
var equipment_visual: Node2D
var weapon_contacts: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://resources/equipment/contacts.json"))

signal fallen
signal resources_changed(energy: float, max_energy: float, stamina: float, max_stamina: float)
signal action_failed(reason: String)
enum State { IDLE, WALK, ATTACK, HURT, DEATH }
## Clockwise 45-degree sectors in screen space. Input.get_vector caps diagonal
## length at one; facing changes the artwork/aim, never the movement speed.
const FACING_NAMES: Array[String] = ["right", "down_right", "down", "down_left", "left", "up_left", "up", "up_right"]
const FACING_VECTORS: Array[Vector2] = [Vector2.RIGHT, Vector2(0.7071067811865476,0.7071067811865476), Vector2.DOWN, Vector2(-0.7071067811865476,0.7071067811865476), Vector2.LEFT, Vector2(-0.7071067811865476,-0.7071067811865476), Vector2.UP, Vector2(0.7071067811865476,-0.7071067811865476)]
const ATTACK_DURATION: float = 0.27
const HURT_DURATION: float = 0.22
const DEATH_DURATION: float = 0.9
const SPRINT_COST: float = 18.0
const STAMINA_REGEN: float = 20.0
const STAMINA_REGEN_DELAY: float = 0.6
const STAMINA_RESTART: float = 20.0
const ENERGY_REGEN: float = 3.0
const ENERGY_REGEN_DELAY: float = 1.5
const EMPOWERED_COST: float = 20.0
const EMPOWERED_MULTIPLIER: float = 1.8
const CRITICAL_MULTIPLIER: float = 1.5
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
var max_energy: float = 50.0
var energy: float = 50.0
var max_stamina: float = 100.0
var stamina: float = 100.0
var luck: int = 0
var strength: int = 10
var defense: int = 0
var crit_chance: float = 0.0
var crit_rng := RandomNumberGenerator.new()
var last_swing_critical: bool = false
var sprinting: bool = false
var sprint_exhausted: bool = false
var _energy_regen_delay: float = 0.0
var _stamina_regen_delay: float = 0.0
var cooldown: float = 0.0
var state_time: float = 0.0
var knockback := Vector2.ZERO
var death_announced: bool = false
@onready var sprite: AnimatedSprite2D = $Sprite
@onready var interaction: Node = $Interaction
@onready var health: Node = $Health
@onready var melee: Node2D = $Melee

func _ready() -> void:
	equipment_visual = preload("res://scripts/player/equipment_visual.gd").new()
	add_child(equipment_visual)
	equipment_visual.setup(sprite)
	var initial: Dictionary = preload("res://scripts/inventory/inventory.gd").STARTER.duplicate(true)
	initial.weapon_right = "rust_sword"
	equipment_visual.apply_equipment(initial)
	crit_rng.randomize()
	health.damaged.connect(_on_damaged)
	melee.contact.connect(_on_swing_contact)

func _physics_process(delta: float) -> void:
	cooldown = maxf(0.0,cooldown-delta)
	state_time -= delta
	if health.current <= 0:
		# A death pose must not retain the final red invulnerability flash.
		sprite.modulate = Color.WHITE
		sprinting = false
		if state != State.DEATH:
			state = State.DEATH
			state_time = DEATH_DURATION
			melee.cancel()
		_sync_action_frame("death_"+facing, DEATH_DURATION-state_time)
		velocity = Vector2.ZERO
		if state_time <= 0 and not death_announced:
			death_announced = true
			fallen.emit()
		return
	sprite.modulate = Color(1.8,0.7,0.6) if health.immunity > 0 and fmod(health.immunity,0.16)>0.08 else Color.WHITE
	if state == State.HURT and state_time > 0:
		_tick_resources(delta,false)
		_sync_action_frame("hurt_"+facing, HURT_DURATION-state_time)
		velocity = knockback
		knockback = knockback.move_toward(Vector2.ZERO,delta*450)
		move_and_slide()
		return
	if state == State.ATTACK and state_time > 0:
		_tick_resources(delta,false)
		_sync_action_frame("attack_"+facing, ATTACK_DURATION-state_time)
		velocity = Vector2.ZERO
		return
	var direction := Vector2.ZERO
	if input_enabled:
		direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	var wants_sprint: bool = direction.length_squared() > 0 and Input.is_action_pressed("sprint") and not sprint_exhausted and stamina > 0.0
	velocity = direction * (run_speed if wants_sprint else walk_speed)
	state = State.WALK if direction.length_squared() > 0.0 else State.IDLE
	if state == State.WALK:
		facing = _facing_from_vector(direction)
	var before_move: Vector2 = position
	move_and_slide()
	# A held Shift against a wall is not a running movement and spends nothing.
	_tick_resources(delta,wants_sprint and position.distance_squared_to(before_move) > 0.000001)
	if state == State.WALK:
		stride_distance += position.distance_to(before_move)
		if stride_distance >= (16.0 if sprinting else 12.0):
			stride_distance = 0.0
			step_left = not step_left
			FOOTSTEP_EFFECT.spawn(get_parent(),FOOTSTEP_ART,global_position+Vector2(-3 if step_left else 3,1),Vector2(12,12))
	else:
		stride_distance = 0.0
	_play_locomotion()
	sprite.speed_scale = (1.45 if sprinting else 1.0) * walk_speed / 72.0 if state == State.WALK else 1.0

func _facing_from_vector(direction: Vector2) -> String:
	if direction.is_zero_approx():
		return facing
	return FACING_NAMES[posmod(roundi(direction.angle() / (PI / 4.0)), 8)]

func _play_locomotion() -> void:
	var animation_name: String = ("walk_" if state == State.WALK else "idle_") + facing
	# A turn during the stride changes the view without restarting the gait.
	var keep_stride: bool = state == State.WALK and str(sprite.animation).begins_with("walk_") and str(sprite.animation) != animation_name
	var previous_frame: int = sprite.frame
	var previous_progress: float = sprite.frame_progress
	sprite.play(animation_name)
	if keep_stride:
		sprite.set_frame_and_progress(previous_frame, previous_progress)

func apply_stats(values: Dictionary, refill: bool = false) -> void:
	# Main applies weapon base + damage_bonus exactly once. This method only
	# applies the player's derived vital/defense/speed/critical properties.
	var previous_max_hp: int = health.maximum
	var previous_hp: int = health.current
	health.maximum = maxi(1,int(values.get("max_health",100)))
	if refill:
		health.current = health.maximum
	elif previous_hp > 0:
		health.current = clampi(previous_hp+health.maximum-previous_max_hp,1,health.maximum)
	else:
		health.current = 0
	var previous_max_energy: float = max_energy
	var previous_max_stamina: float = max_stamina
	max_energy = maxf(1.0,float(values.get("max_energy",50)))
	max_stamina = maxf(1.0,float(values.get("max_stamina",100)))
	energy = max_energy if refill else clampf(energy+max_energy-previous_max_energy,0.0,max_energy)
	stamina = max_stamina if refill else clampf(stamina+max_stamina-previous_max_stamina,0.0,max_stamina)
	walk_speed = maxf(1.0,float(values.get("walk_speed",72.0)))
	run_speed = maxf(walk_speed,float(values.get("run_speed",112.0)))
	luck = maxi(0,int(values.get("luck",0)))
	strength = maxi(0,int(values.get("strength",10)))
	defense = maxi(0,int(values.get("defense",0)))
	crit_chance = clampf(float(values.get("crit_chance",0.0)),0.0,0.499999999)
	health.damage_reduction = float(values.get("damage_reduction",0.0))
	if refill:
		_energy_regen_delay = 0.0
		_stamina_regen_delay = 0.0
		sprint_exhausted = false
	health.changed.emit(health.current,health.maximum)
	_emit_resources()

func restore_vitals(energy_value: float, stamina_value: float) -> void:
	if not is_finite(energy_value) or not is_finite(stamina_value):
		return
	energy = clampf(energy_value,0.0,max_energy)
	stamina = clampf(stamina_value,0.0,max_stamina)
	# Recovery clocks are transient; loading never grants an instant regen tick.
	_energy_regen_delay = ENERGY_REGEN_DELAY
	_stamina_regen_delay = STAMINA_REGEN_DELAY
	sprint_exhausted = stamina < STAMINA_RESTART
	_emit_resources()

func _tick_resources(delta: float, running: bool) -> void:
	sprinting = running and input_enabled and health.current > 0
	if not input_enabled or health.current <= 0:
		return
	var previous_energy: float = energy
	var previous_stamina: float = stamina
	var energy_time: float = maxf(0.0,delta-_energy_regen_delay)
	_energy_regen_delay = maxf(0.0,_energy_regen_delay-delta)
	energy = minf(max_energy,energy+ENERGY_REGEN*energy_time)
	if sprinting:
		stamina = maxf(0.0,stamina-SPRINT_COST*delta)
		_stamina_regen_delay = STAMINA_REGEN_DELAY
		if stamina <= 0.0:
			sprint_exhausted = true
	else:
		var stamina_time: float = maxf(0.0,delta-_stamina_regen_delay)
		_stamina_regen_delay = maxf(0.0,_stamina_regen_delay-delta)
		stamina = minf(max_stamina,stamina+STAMINA_REGEN*stamina_time)
	if sprint_exhausted and stamina >= STAMINA_RESTART:
		sprint_exhausted = false
	if not is_equal_approx(previous_energy,energy) or not is_equal_approx(previous_stamina,stamina):
		_emit_resources()

func _emit_resources() -> void:
	resources_changed.emit(energy,max_energy,stamina,max_stamina)

func aim_vector() -> Vector2:
	var index: int = FACING_NAMES.find(facing)
	return FACING_VECTORS[index] if index >= 0 else Vector2.DOWN

func set_equipment(equipment: Dictionary) -> void:
	if not is_instance_valid(equipment_visual): return
	if equipment_visual.loadout != equipment and state == State.ATTACK:
		# A weapon/clothing swap must not leave an old hit armed under new art.
		# Keep its already-paid mana and cooldown, like any interrupted swing.
		melee.cancel()
		state = State.IDLE
		state_time = 0.0
		sprite.speed_scale = 1.0
		sprite.play("idle_"+facing)
	equipment_visual.apply_equipment(equipment)

func attack(mouse_aim: bool = false) -> bool:
	return _begin_attack(mouse_aim,false)

func empowered_attack(mouse_aim: bool = false) -> bool:
	return _begin_attack(mouse_aim,true)

func _begin_attack(mouse_aim: bool, empowered: bool) -> bool:
	var reason: String = ""
	if not input_enabled:
		reason = "Chưa thể hành động khi đang mở giao diện."
	elif health.current <= 0:
		reason = "Không thể tấn công khi đã gục ngã."
	elif cooldown > 0 or melee.remaining > 0:
		reason = "Đòn đánh đang hồi."
	elif state == State.HURT:
		reason = "Chưa thể tấn công khi đang bị thương."
	elif weapon_damage <= 0:
		reason = "Cần trang bị vũ khí để tấn công."
	elif empowered and energy < EMPOWERED_COST:
		reason = "Cần 20 năng lượng để chém cường hóa."
	if not reason.is_empty():
		action_failed.emit(reason)
		return false
	if mouse_aim:
		var aim: Vector2 = get_global_mouse_position()-global_position
		if aim.length() > 5:
			facing = _facing_from_vector(aim)
	var hand: String = "weapon_right" if not str(equipment_visual.loadout.get("weapon_right","")).is_empty() else "weapon_left"
	var contact: Array = weapon_contacts[facing][hand]
	melee.weapon_contact_tip = Vector2(contact[0],contact[1])
	if not melee.begin(aim_vector(),weapon_damage,empowered):
		action_failed.emit("Đòn đánh chưa sẵn sàng.")
		return false
	# Roll once only after a swing really begins; luck zero consumes no RNG state.
	last_swing_critical = crit_chance > 0.0 and crit_rng.randf() < crit_chance
	var amount: float = weapon_damage*(EMPOWERED_MULTIPLIER if empowered else 1.0)
	if last_swing_critical:
		amount *= CRITICAL_MULTIPLIER
	melee.damage = maxi(1,roundi(amount))
	if empowered:
		energy -= EMPOWERED_COST
		_energy_regen_delay = ENERGY_REGEN_DELAY
		_emit_resources()
	state = State.ATTACK
	state_time = ATTACK_DURATION
	cooldown = 0.44
	_sync_action_frame("attack_"+facing, 0.0)
	return true

func _on_damaged(_amount: int, direction: Vector2) -> void:
	# Once the attack pose is interrupted, its deferred contact must stop too.
	melee.cancel()
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
	sprinting = false
	sprite.speed_scale = 1.0
	if state in [State.IDLE,State.WALK]:
		state = State.IDLE
		sprite.play("idle_" + facing)
