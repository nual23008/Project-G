extends Area2D
## Receiver owns a Health component. Layer 4 (bit 8) is reserved for hurtboxes.
const EFFECT := preload("res://scripts/combat/sprite_effect.gd")
const HIT_SPARK: SpriteFrames = preload("res://resources/art/hit_spark.tres")
var health: Node

func _ready() -> void:
	health = get_parent().get_node("Health")
	collision_layer = 8
	collision_mask = 0
	monitoring = false
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 9.0
	shape.shape = circle
	add_child(shape)

func receive(amount: int, origin: Vector2) -> bool:
	var accepted: bool = health.damage(amount, (global_position-origin).normalized())
	if accepted:
		EFFECT.spawn(get_parent().get_parent(), HIT_SPARK, global_position+Vector2(0,-25), Vector2(16,16))
	return accepted
