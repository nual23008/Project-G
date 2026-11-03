extends Node2D
## Every layer samples the exact base animation/frame, including physics contact.
const RACES := preload("res://scripts/character/races.gd")
const ORDER: Array[String] = ["pants","shoe_left","shoe_right","shirt","bare_hands","glove_left","glove_right","bracelet_left","bracelet_right","necklace","heritage","hat","weapon_left","weapon_right"]
var base: AnimatedSprite2D
var parts: Dictionary = {}
var loadout: Dictionary = {}
var race_id: String = ""
var _last_animation: StringName = &""
var _last_frame: int = -1

func setup(actor: AnimatedSprite2D, selected_race: String = "human") -> void:
	base = actor
	base.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	base.frame_changed.connect(sync_pose)
	base.animation_changed.connect(sync_pose)
	for slot: String in ORDER:
		var part := AnimatedSprite2D.new()
		part.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		part.name = "Equipment_"+slot
		part.centered = false
		part.offset = Vector2(-48,-60)
		part.set_meta(&"pose_clock",base)
		# Keep depth local to the actor: negative Z would bury blades below
		# terrain/UI panels and changing Z would break the world Y-sort.
		base.add_child(part)
		parts[slot] = part

	set_race(selected_race)

func set_race(id: String) -> void:
	if not RACES.valid(id) or race_id == id: return
	race_id = id
	var animation: StringName = base.animation
	base.sprite_frames = RACES.frames(id,"player")
	if base.sprite_frames.has_animation(animation): base.animation = animation
	var previous: Dictionary = loadout.duplicate(true)
	loadout.clear()
	for part: AnimatedSprite2D in parts.values(): part.sprite_frames = null
	apply_equipment(previous,true)

func apply_equipment(equipment: Dictionary, force: bool = false) -> void:
	if not force and loadout == equipment: return
	var previous: Dictionary = loadout
	loadout = equipment.duplicate(true)
	for slot: String in ORDER:
		var part: AnimatedSprite2D = parts[slot]
		var id: String = str(equipment.get(slot,""))
		if slot == "bare_hands":
			part.visible = true
			part.sprite_frames = RACES.frames(race_id,"player_hands")
			continue
		if slot == "heritage":
			part.visible = race_id != "human"
			if part.visible: part.sprite_frames = RACES.frames(race_id,"heritage")
			continue
		if previous.get(slot,"") == id and part.sprite_frames != null: continue
		part.visible = not id.is_empty()
		if not id.is_empty():
			part.sprite_frames = RACES.frames(race_id,"gear_"+id+"_"+slot)
	sync_pose(true)

func sync_pose(force: bool = false) -> void:
	if not is_instance_valid(base): return
	if not force and base.animation == _last_animation and base.frame == _last_frame: return
	var direction: String = String(base.animation).substr(String(base.animation).find("_")+1)
	_last_animation = base.animation
	_last_frame = base.frame
	for part: AnimatedSprite2D in parts.values():
		if not part.visible or part.sprite_frames == null: continue
		if part.name in ["Equipment_weapon_left","Equipment_weapon_right"]:
			var far_hand: bool = (direction == "right" and part.name == "Equipment_weapon_left") or (direction == "left" and part.name == "Equipment_weapon_right")
			part.show_behind_parent = direction.begins_with("up") or far_hand
		part.animation = base.animation
		part.pause()
		part.set_frame_and_progress(base.frame,base.frame_progress)

func _exit_tree() -> void:
	for part: AnimatedSprite2D in parts.values():
		if is_instance_valid(part) and part.is_inside_tree(): part.queue_free()
