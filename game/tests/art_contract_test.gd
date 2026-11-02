extends SceneTree
## The art registry is a build contract: missing files, stale metadata and fake
## multi-frame animations must fail before a gameplay regression is accepted.
const MANIFEST_PATH: String = "res://resources/art/manifest.json"
var checks: int = 0
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, description: String) -> void:
	checks += 1
	print("PASS: " if value else "FAIL: ", description)
	if not value:
		failures.append(description)

func run() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
	check(parsed is Dictionary and not parsed.is_empty(), "Art manifest exists and contains asset records")
	if not parsed is Dictionary or parsed.is_empty():
		finish()
		return
	var registry: Dictionary = parsed
	var required_ids: Array[String] = ["player", "rowan", "enemy", "house", "pine", "oak", "rock", "lamp", "crystal", "fence", "sign", "fern", "flowers", "chest", "portal", "rust_sword", "potion", "herb", "ore", "echo_shard", "sword_slash", "enemy_strike", "hit_spark", "grass", "stone_path", "water", "shore", "ui_panel", "ui_button", "ui_health", "firefly", "glow"]
	for id: String in required_ids:
		check(registry.has(id), "Visible type has a registered art resource: " + id)
	for id: String in registry:
		if not registry[id] is Dictionary:
			check(false, id + ": manifest entry is a dictionary")
			continue
		validate_asset(id, registry[id])
	finish()

func validate_asset(id: String, entry: Dictionary) -> void:
	var metadata_valid: bool = entry.get("resource") is String and entry.get("texture") is String and entry.get("source") is String and not str(entry.get("source", "")).is_empty() and entry.get("backend") is String and entry.get("frame_size") is Array and entry.frame_size.size() == 2 and entry.get("pivot") is Array and entry.pivot.size() == 2 and entry.get("states") is Dictionary and not entry.states.is_empty() and is_integer(entry.get("columns")) and int(entry.columns) > 0
	check(metadata_valid, id + ": source, dimensions, pivot and state metadata declared")
	if not metadata_valid:
		return
	var dimensions_valid: bool = is_integer(entry.frame_size[0]) and is_integer(entry.frame_size[1]) and int(entry.frame_size[0]) > 0 and int(entry.frame_size[1]) > 0
	check(dimensions_valid, id + ": frame dimensions are positive integers")
	if not dimensions_valid:
		return
	var frame_size := Vector2i(int(entry.frame_size[0]), int(entry.frame_size[1]))
	var pivot_valid: bool = is_number(entry.pivot[0]) and is_number(entry.pivot[1]) and float(entry.pivot[0]) >= 0 and float(entry.pivot[0]) <= frame_size.x and float(entry.pivot[1]) >= 0 and float(entry.pivot[1]) <= frame_size.y
	check(pivot_valid, id + ": declared pivot lies inside frame")
	var resource: Resource = load(str(entry.resource))
	var texture: Resource = load(str(entry.texture))
	check(resource is SpriteFrames and texture is Texture2D, id + ": SpriteFrames and sheet load in Godot")
	if not resource is SpriteFrames or not texture is Texture2D:
		return
	var sprite_frames: SpriteFrames = resource
	var sheet: Texture2D = texture
	var expected_width: int = frame_size.x * int(entry.columns)
	var sheet_valid: bool = sheet.get_width() == expected_width and sheet.get_height() % frame_size.y == 0
	check(sheet_valid, id + ": sheet dimensions match frame grid")
	check(sprite_frames.get_animation_names().size() == entry.states.size(), id + ": resource animation count matches manifest")
	var rows: int = sheet.get_height() / frame_size.y
	for state_name: String in entry.states:
		var state_record: Variant = entry.states[state_name]
		var state_texture: String = str(state_record.get("texture", entry.texture)) if state_record is Dictionary else str(entry.texture)
		var state_columns: int = int(state_record.get("columns", entry.columns)) if state_record is Dictionary else int(entry.columns)
		var state_rows: int = rows
		if state_texture != str(entry.texture):
			var alternate: Texture2D = load(state_texture)
			var alternate_valid: bool = alternate != null and state_columns > 0 and alternate.get_width() == state_columns * frame_size.x and alternate.get_height() % frame_size.y == 0
			check(alternate_valid, id + "/" + state_name + ": alternate sheet matches declared grid")
			if not alternate_valid:
				continue
			state_rows = alternate.get_height() / frame_size.y
		validate_state(id, state_name, state_record, sprite_frames, state_texture, frame_size, state_columns, state_rows)
	if id in ["sword_slash", "enemy_strike"]:
		validate_contact(id, entry, sprite_frames)
	if id == "player":
		for direction: String in ["down", "left", "right", "up"]:
			for state_name: String in ["idle", "walk", "attack", "hurt", "death"]:
				check(sprite_frames.has_animation(state_name + "_" + direction), "Player behavior has directional animation: " + state_name + "_" + direction)

func validate_contact(id: String, entry: Dictionary, sprite_frames: SpriteFrames) -> void:
	var valid: bool = is_integer(entry.get("contact_frame")) and is_number(entry.get("contact_time")) and is_number(entry.get("duration")) and sprite_frames.has_animation("play")
	check(valid, id + ": contact frame and damage time declared")
	if not valid:
		return
	var contact: int = int(entry.contact_frame)
	var fps: float = sprite_frames.get_animation_speed("play")
	var count: int = sprite_frames.get_frame_count("play")
	if fps <= 0:
		check(false, id + ": contact animation has a positive playback rate")
		return
	check(contact >= 0 and contact < count and float(entry.contact_time) >= contact / fps and float(entry.contact_time) < (contact + 1) / fps, id + ": damage time falls within visible contact frame")
	check(is_equal_approx(count / fps, float(entry.duration)) and is_equal_approx(float(entry.duration), 0.24), id + ": slash playback preserves combat duration")

func validate_state(id: String, state_name: String, record: Variant, sprite_frames: SpriteFrames, texture_path: String, frame_size: Vector2i, columns: int, rows: int) -> void:
	var label: String = id + "/" + state_name
	var valid: bool = record is Dictionary and record.get("indices") is Array and is_integer(record.get("count")) and int(record.count) > 0 and record.indices.size() == int(record.count) and is_number(record.get("fps")) and float(record.fps) > 0 and record.get("loop") is bool
	check(valid and sprite_frames.has_animation(state_name), label + ": state metadata and animation exist")
	if not valid or not sprite_frames.has_animation(state_name):
		return
	var count: int = sprite_frames.get_frame_count(state_name)
	check(count == int(record.count) and is_equal_approx(sprite_frames.get_animation_speed(state_name), float(record.fps)) and sprite_frames.get_animation_loop(state_name) == bool(record.loop), label + ": frame count, FPS and loop match resource")
	var regions_valid: bool = true
	var distinct_images: Dictionary = {}
	for index: int in range(count):
		var frame: Texture2D = sprite_frames.get_frame_texture(state_name, index)
		if index >= record.indices.size() or not is_integer(record.indices[index]) or frame == null or not frame is AtlasTexture:
			regions_valid = false
			continue
		var atlas: AtlasTexture = frame
		var sheet_index: int = int(record.indices[index])
		var expected_region := Rect2((sheet_index % columns) * frame_size.x, (sheet_index / columns) * frame_size.y, frame_size.x, frame_size.y)
		regions_valid = regions_valid and sheet_index >= 0 and sheet_index < columns * rows and atlas.atlas != null and atlas.atlas.resource_path == texture_path and atlas.region == expected_region and is_equal_approx(sprite_frames.get_frame_duration(state_name, index), 1.0)
		var image: Image = frame.get_image()
		if image == null or image.is_empty():
			regions_valid = false
		else:
			distinct_images[image.get_data().hex_encode()] = true
	check(regions_valid, label + ": atlas frames match declared cells and timing")
	check(count <= 1 or distinct_images.size() > 1, label + ": multi-frame animation contains real pixel changes")

func is_number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))

func is_integer(value: Variant) -> bool:
	return is_number(value) and float(value) == floorf(float(value))

func finish() -> void:
	print("RESULT: ", checks - failures.size(), "/", checks, " art contract checks passed")
	quit(0 if failures.is_empty() else 1)
