extends CharacterBody2D
signal defeated(id: String, at: Vector2, loot: Array)
enum State { PATROL, CHASE, WINDUP, RECOVER, RETURN, HURT, DEAD }
const HEALTH := preload("res://scripts/combat/health.gd")
const HURTBOX := preload("res://scripts/combat/hurtbox.gd")
const MELEE := preload("res://scripts/combat/melee.gd")
const ENEMY_FRAMES: SpriteFrames = preload("res://resources/art/enemy.tres")
const TELEGRAPH_FRAMES: SpriteFrames = preload("res://resources/art/enemy_telegraph.tres")
const HEALTH_SKIN: SpriteFrames = preload("res://resources/art/ui_health.tres")
const RECOVER_DURATION: float = 0.42
const HURT_DURATION: float = 0.18
var enemy_id: String = ""
var definition: Dictionary = {}
var state: State = State.PATROL
var home := Vector2.ZERO
var patrol_end := Vector2.ZERO
var state_time: float = 0.0
var cooldown: float = 0.0
var knockback := Vector2.ZERO
var target: CharacterBody2D
var health: Node
var melee: Node2D
var sprite: AnimatedSprite2D
var telegraph: AnimatedSprite2D
var death_duration: float = 0.0
var path_clock: float = 0.0
var waypoint := Vector2.ZERO
var towards_end: bool = true
var ambient_time: float = 0.0

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 16
	collision_mask = 19
	definition = JSON.parse_string(FileAccess.get_file_as_string("res://resources/enemies/guardian.json"))
	home = position
	patrol_end = home+Vector2(36,0)
	var feet := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 7
	feet.shape = circle
	add_child(feet)
	health = HEALTH.new()
	health.name = "Health"
	health.maximum = int(definition.hp)
	health.current = int(definition.hp)
	add_child(health)
	health.damaged.connect(_damaged)
	health.died.connect(_died)
	var hurtbox := HURTBOX.new()
	add_child(hurtbox)
	melee = MELEE.new()
	melee.team = "enemy"
	add_child(melee)
	melee.contact.connect(_on_swing_contact)
	sprite = AnimatedSprite2D.new()
	sprite.sprite_frames = ENEMY_FRAMES
	sprite.centered = false
	sprite.offset = Vector2(-24,-52)
	sprite.play("walk")
	add_child(sprite)
	telegraph = AnimatedSprite2D.new()
	telegraph.name = "AttackTelegraph"
	telegraph.sprite_frames = TELEGRAPH_FRAMES
	telegraph.centered = false
	telegraph.offset = Vector2(-36,-36)
	telegraph.z_index = -1
	telegraph.animation = &"play"
	telegraph.hide()
	add_child(telegraph)

func _physics_process(delta: float) -> void:
	ambient_time += delta
	cooldown = maxf(0.0,cooldown-delta)
	state_time -= delta
	path_clock -= delta
	if state == State.DEAD:
		_sync_action_frame("death",death_duration-state_time)
		if state_time <= 0:
			queue_free()
		return
	if not is_instance_valid(target) or target.health.current <= 0:
		state = State.RETURN
	var distance: float = global_position.distance_to(target.global_position) if is_instance_valid(target) else INF
	var visible_target: bool = distance < float(definition.detection) and _sees_target()
	if state == State.HURT:
		velocity = knockback
		knockback = knockback.move_toward(Vector2.ZERO,delta*350)
		move_and_slide()
		if state_time <= 0:
			state = State.CHASE
	elif state == State.WINDUP:
		velocity = Vector2.ZERO
		sprite.modulate = Color(1.8,0.65,0.45)
		if state_time <= 0:
			melee.begin((target.global_position-global_position).normalized(),int(definition.damage))
			state = State.RECOVER
			state_time = RECOVER_DURATION
			cooldown = float(definition.cooldown)
	elif state == State.RECOVER:
		if state_time <= 0:
			state = State.CHASE
	else:
		sprite.modulate = Color.WHITE
		if global_position.distance_to(home) > float(definition.leash) or (state == State.CHASE and distance > float(definition.detection)*1.5):
			state = State.RETURN
		elif visible_target and state != State.RETURN and target.health.current > 0:
			state = State.CHASE
		match state:
			State.PATROL:
				var goal: Vector2 = patrol_end if towards_end else home
				if position.distance_to(goal) < 6:
					towards_end = not towards_end
				_move_to(goal,float(definition.walk_speed),delta)
			State.CHASE:
				if distance < float(definition.attack_range) and cooldown <= 0 and _sees_target():
					state = State.WINDUP
					state_time = float(definition.windup)
					velocity = Vector2.ZERO
				else:
					_move_to(target.global_position,float(definition.chase_speed),delta)
			State.RETURN:
				_move_to(home,float(definition.chase_speed),delta)
				if position.distance_to(home)<8:
					state = State.PATROL
	_update_visual()
	queue_redraw()

func _update_visual() -> void:
	telegraph.visible = state == State.WINDUP
	match state:
		State.WINDUP:
			var elapsed: float = float(definition.windup)-state_time
			_sync_action_frame("windup",elapsed)
			var count: int = TELEGRAPH_FRAMES.get_frame_count(&"play")
			telegraph.frame = clampi(int(elapsed/float(definition.windup)*count),0,count-1)
		State.RECOVER:
			var elapsed: float = RECOVER_DURATION-state_time
			if elapsed < melee.duration:
				_sync_action_frame("attack",elapsed)
			else:
				sprite.play("idle")
		State.HURT:
			_sync_action_frame("hurt",HURT_DURATION-state_time)
		_:
			sprite.speed_scale = 1.0
			sprite.play("walk" if velocity.length_squared() > 1 else "idle")

func _sync_action_frame(animation_name: String, elapsed: float) -> void:
	sprite.speed_scale = 1.0
	sprite.animation = animation_name
	sprite.pause()
	sprite.frame = clampi(int(maxf(0.0,elapsed)*ENEMY_FRAMES.get_animation_speed(animation_name)),0,ENEMY_FRAMES.get_frame_count(animation_name)-1)

func _on_swing_contact() -> void:
	if state == State.RECOVER:
		sprite.frame = melee.CONTACT_FRAME

func _move_to(goal: Vector2, speed: float, _delta: float) -> void:
	if path_clock <= 0:
		waypoint = get_parent().get_parent().next_step(global_position,goal)
		path_clock = 0.22
	velocity = (waypoint-global_position).normalized()*speed if global_position.distance_to(goal)>4 else Vector2.ZERO
	move_and_slide()
	sprite.flip_h = velocity.x < 0

func _sees_target() -> bool:
	if not is_instance_valid(target):
		return false
	var ray := PhysicsRayQueryParameters2D.create(global_position,target.global_position,1)
	return get_world_2d().direct_space_state.intersect_ray(ray).is_empty()

func _damaged(_amount: int, direction: Vector2) -> void:
	melee.cancel()
	telegraph.hide()
	if health.current > 0:
		state = State.HURT
		state_time = HURT_DURATION
		knockback = direction*85
		sprite.modulate = Color(2,1,1)
		_sync_action_frame("hurt",0.0)

func _died() -> void:
	state = State.DEAD
	velocity = Vector2.ZERO
	melee.cancel()
	remove_from_group("enemies")
	set_deferred("collision_layer",0)
	set_deferred("collision_mask",0)
	for child: Node in get_children():
		if child is Area2D:
			child.set_deferred("collision_layer",0)
	death_duration = ENEMY_FRAMES.get_frame_count(&"death")/ENEMY_FRAMES.get_animation_speed(&"death")
	state_time = death_duration
	sprite.modulate = Color.WHITE
	telegraph.hide()
	_sync_action_frame("death",0.0)
	# The quest and save state change now; the corpse is only a transient visual.
	defeated.emit(enemy_id,position,definition.loot)
	queue_redraw()

func health_skin_texture() -> Texture2D:
	var frame: int = posmod(int(ambient_time * HEALTH_SKIN.get_animation_speed(&"idle")), HEALTH_SKIN.get_frame_count(&"idle"))
	return HEALTH_SKIN.get_frame_texture(&"idle", frame)

func _draw() -> void:
	if health != null and health.current > 0 and health.current < health.maximum:
		var skin: Texture2D = health_skin_texture()
		draw_texture_rect_region(skin,Rect2(-13,-54,26,3),Rect2(0,0,26,3),Color(0.2,0.18,0.2))
		var width: float = floorf(26.0*health.current/health.maximum)
		draw_texture_rect_region(skin,Rect2(-13,-54,width,3),Rect2(0,0,width,3))
