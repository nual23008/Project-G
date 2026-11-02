extends Node2D
const EFFECT := preload("res://scripts/combat/sprite_effect.gd")
const ART: Dictionary = {
	"rust_sword":preload("res://resources/art/rust_sword.tres"),
	"potion":preload("res://resources/art/potion.tres"),
	"herb":preload("res://resources/art/herb.tres"),
	"ore":preload("res://resources/art/ore.tres"),
	"echo_shard":preload("res://resources/art/echo_shard.tres"),
	"chest":preload("res://resources/art/chest.tres"),
	"portal":preload("res://resources/art/portal.tres")
}
static var manifest: Dictionary = {}
@export var object_id: String = ""
var data: Dictionary = {}
var display_name: String = ""
var visual: AnimatedSprite2D
var pivot := Vector2.ZERO

func setup(entry: Dictionary) -> void:
	data = entry.duplicate(true)
	object_id = str(data.id)
	display_name = str(data.get("name","Nhặt vật phẩm"))
	position = Vector2(data.at[0],data.at[1])

func _ready() -> void:
	add_to_group("interactables")
	var art_id: String = str(data.item) if data.kind in ["pickup","drop","shard"] else str(data.kind)
	if manifest.is_empty():
		manifest = JSON.parse_string(FileAccess.get_file_as_string("res://resources/art/manifest.json"))
	var anchor: Array = manifest[art_id].pivot
	pivot = Vector2(anchor[0],anchor[1])
	visual = AnimatedSprite2D.new()
	visual.name = "ObjectSprite"
	visual.sprite_frames = ART[art_id]
	visual.centered = false
	visual.offset = -pivot
	add_child(visual)
	visual.play("idle")
	visual.frame = posmod(hash(object_id),visual.sprite_frames.get_frame_count(&"idle"))

func interact_data() -> Dictionary:
	return data

func play_collected() -> void:
	# Main commits the inventory transaction before Village calls this hook.
	# Detaching only the transient visual keeps collection/save semantics immediate.
	var state: StringName = &"open" if data.kind == "chest" else &"pickup"
	if visual.sprite_frames.has_animation(state):
		EFFECT.spawn(get_parent(),visual.sprite_frames,global_position,pivot,state)
