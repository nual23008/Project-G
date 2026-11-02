extends Node2D
@export var object_id: String = ""
var data: Dictionary = {}
var display_name: String = ""

func setup(entry: Dictionary) -> void:
	data = entry.duplicate(true)
	object_id = str(data.id)
	display_name = str(data.get("name","Nhặt vật phẩm"))
	position = Vector2(data.at[0],data.at[1])

func _ready() -> void:
	add_to_group("interactables")
	var visual := Sprite2D.new()
	if data.kind in ["pickup","drop","shard"]:
		var atlas := AtlasTexture.new()
		atlas.atlas = preload("res://assets/sprites/items.png")
		var database: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://resources/items/items.json"))
		atlas.region = Rect2(int(database[data.item].icon)*16,0,16,16)
		visual.texture = atlas
	elif data.kind == "chest":
		visual.texture = preload("res://assets/sprites/chest.png")
	else:
		visual.texture = preload("res://assets/sprites/portal.png")
	visual.position.y = -8
	add_child(visual)

func interact_data() -> Dictionary:
	return data
