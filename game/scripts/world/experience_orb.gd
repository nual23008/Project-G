extends Node2D
## A saved world drop, not an inventory item. No XP is awarded until claimed.
signal collected(orb: Node2D)
const FRAMES: SpriteFrames = preload("res://resources/art/experience_orb.tres")
const EFFECT := preload("res://scripts/combat/sprite_effect.gd")
var data: Dictionary = {}
var object_id: String = ""
var target: CharacterBody2D
var claimed: bool = false
var sprite: AnimatedSprite2D

func setup(entry: Dictionary) -> void:
	data = entry.duplicate(true)
	object_id = str(data.id)
	position = Vector2(data.at[0], data.at[1])

func _ready() -> void:
	add_to_group("experience_orbs")
	sprite = AnimatedSprite2D.new()
	sprite.name = "ExperienceSprite"
	sprite.sprite_frames = FRAMES
	sprite.centered = false
	sprite.offset = Vector2(-8, -16)
	add_child(sprite)
	sprite.play(&"idle")
	sprite.frame = posmod(hash(object_id), FRAMES.get_frame_count(&"idle"))

func _physics_process(delta: float) -> void:
	if claimed or not is_instance_valid(target) or target.hp <= 0 or not target.input_enabled:
		return
	var distance: float = global_position.distance_to(target.global_position)
	if distance > 64.0:
		return
	var ray := PhysicsRayQueryParameters2D.create(global_position, target.global_position, 1)
	if not get_world_2d().direct_space_state.intersect_ray(ray).is_empty():
		return
	if distance <= 12.0:
		claimed = true
		set_physics_process(false)
		collected.emit(self)
		return
	global_position = global_position.move_toward(target.global_position, 140.0 * delta)

func play_collected() -> void:
	EFFECT.spawn(get_parent(), FRAMES, global_position, Vector2(8, 16), &"collect")
