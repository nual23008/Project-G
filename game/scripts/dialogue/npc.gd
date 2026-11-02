extends StaticBody2D

@export var npc_id: String = "rowan"
@export var display_name: String = "Rowan"
@export var dialogue_id: String = "rowan"

func _ready() -> void:
	add_to_group("interactables")
