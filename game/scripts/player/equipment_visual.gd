extends Node2D
## Every layer samples the exact base animation/frame, including physics contact.
const ORDER: Array[String] = ["pants","shoe_left","shoe_right","shirt","bare_hands","glove_left","glove_right","bracelet_left","bracelet_right","necklace","hat","weapon_left","weapon_right"]
var base: AnimatedSprite2D
var parts: Dictionary = {}
var loadout: Dictionary = {}

func setup(actor: AnimatedSprite2D) -> void:
	base = actor
	base.frame_changed.connect(sync_pose)
	base.animation_changed.connect(sync_pose)
	for slot: String in ORDER:
		var part := AnimatedSprite2D.new()
		part.name = "Equipment_"+slot
		part.centered = false
		part.offset = Vector2(-48,-60)
		part.set_meta(&"pose_clock",base)
		add_child(part)
		parts[slot] = part

func apply_equipment(equipment: Dictionary) -> void:
	loadout = equipment.duplicate(true)
	for slot: String in ORDER:
		var part: AnimatedSprite2D = parts[slot]
		var id: String = str(equipment.get(slot,""))
		if slot == "bare_hands":
			part.visible = true
			part.sprite_frames = preload("res://resources/art/player_hands.tres")
			continue
		part.visible = not id.is_empty()
		if not id.is_empty():
			part.sprite_frames = load("res://resources/art/gear_"+id+"_"+slot+".tres")
	sync_pose()

func sync_pose() -> void:
	if not is_instance_valid(base): return
	for part: AnimatedSprite2D in parts.values():
		if not part.visible or part.sprite_frames == null: continue
		part.animation = base.animation
		part.pause()
		part.set_frame_and_progress(base.frame,base.frame_progress)

func _process(_delta: float) -> void:
	if is_instance_valid(base):
		modulate = base.modulate
		sync_pose()
