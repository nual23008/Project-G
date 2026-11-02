extends RefCounted
## Single-slot versioned save; checksum, schema validation, temp+atomic rename and backup.
const VERSION: int = 1
var path: String = "user://journey.json"
var last_error: String = ""
var recovered_backup: bool = false
var items: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://resources/items/items.json"))
var quest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://resources/quests/first_echo.json"))

func read_valid(file_path: String) -> Dictionary:
	if not FileAccess.file_exists(file_path):
		return {}
	var file := FileAccess.open(file_path,FileAccess.READ)
	if file == null:
		return {}
	if file.get_length()>2000000:
		file.close()
		return {}
	var raw: String = file.get_as_text()
	file.close()
	var parser := JSON.new()
	if parser.parse(raw) != OK or not parser.data is Dictionary:
		return {}
	var envelope: Dictionary = parser.data
	if envelope.get("version") != VERSION or not envelope.get("payload") is String or not envelope.get("checksum") is String:
		return {}
	var payload: String = envelope.payload
	if payload.sha256_text() != envelope.checksum or parser.parse(payload) != OK:
		return {}
	return parser.data if valid_snapshot(parser.data) else {}

func load_game() -> Dictionary:
	recovered_backup = false
	var data: Dictionary = read_valid(path)
	if data.is_empty():
		data = read_valid(path+".bak")
		recovered_backup = not data.is_empty()
	last_error = "Không tìm thấy bản lưu hợp lệ (bản chính và dự phòng)." if data.is_empty() else ""
	return data

func has_save() -> bool:
	return not read_valid(path).is_empty() or not read_valid(path+".bak").is_empty()

func save_game(snapshot: Dictionary) -> bool:
	last_error = ""
	if not valid_snapshot(snapshot):
		last_error = "Trạng thái chưa hợp lệ để lưu."
		return false
	var payload: String = JSON.stringify(snapshot)
	var encoded: String = JSON.stringify({"version":VERSION,"payload":payload,"checksum":payload.sha256_text()})
	if not _write(path+".tmp",encoded) or read_valid(path+".tmp").is_empty():
		last_error = "Không ghi hoặc xác minh được file tạm; bản lưu cũ được giữ lại."
		return false
	# Never replace a good backup with a corrupt primary file.
	if not read_valid(path).is_empty():
		if not _write(path+".bak.tmp",FileAccess.get_file_as_string(path)) or read_valid(path+".bak.tmp").is_empty():
			last_error = "Không tạo được dự phòng; giữ nguyên bản lưu cũ."
			return false
		if DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".bak.tmp"),ProjectSettings.globalize_path(path+".bak")) != OK:
			last_error = "Không thay được bản dự phòng; giữ nguyên bản lưu cũ."
			return false
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path)) != OK:
		last_error = "Không hoàn tất lưu; bản lưu cũ được giữ lại."
		return false
	return true

func _write(file_path: String, content: String) -> bool:
	var file := FileAccess.open(file_path,FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(content)
	file.flush()
	var error: Error = file.get_error()
	file.close()
	return error == OK

func _integer(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value)==floorf(float(value)) and float(value)>=minimum and float(value)<=maximum

func _point(value: Variant) -> bool:
	return value is Array and value.size()==2 and (value[0] is int or value[0] is float) and (value[1] is int or value[1] is float) and is_finite(float(value[0])) and is_finite(float(value[1])) and float(value[0])>=16 and float(value[0])<=1008 and float(value[1])>=16 and float(value[1])<=752

func _ids(value: Variant) -> bool:
	if not value is Array or value.size()>512:
		return false
	var seen: Dictionary = {}
	for id: Variant in value:
		if not id is String or id.is_empty() or id.length()>100 or seen.has(id):
			return false
		seen[id] = true
	return true

func valid_snapshot(data: Variant) -> bool:
	if not data is Dictionary or not data.get("zone") in ["dawn_village","whispering_forest"] or not _point(data.get("position")) or not _integer(data.get("hp"),1,100):
		return false
	if not data.get("inventory") is Array or data.inventory.size()!=16:
		return false
	for slot: Variant in data.inventory:
		if not slot is Dictionary:
			return false
		if not slot.is_empty() and (not items.has(slot.get("id")) or not _integer(slot.get("count"),1,int(items[slot.id].max_stack))):
			return false
	var progress: Variant = data.get("quest")
	if not progress is Dictionary or not progress.get("status") in ["available","active","completed"] or not progress.get("reward_claimed") is bool or not progress.get("events") is Dictionary:
		return false
	var valid_events: Dictionary = {}
	for objective: Dictionary in quest.objectives:
		valid_events[str(objective.event)+":"+str(objective.target)] = int(objective.count)
	for key: Variant in progress.events:
		if not valid_events.has(key) or not _integer(progress.events[key],0,int(valid_events[key])):
			return false
	var all_done: bool = true
	for key: String in valid_events:
		all_done = all_done and int(progress.events.get(key,0))>=int(valid_events[key])
	if (progress.status=="completed") != all_done or bool(progress.reward_claimed) != (progress.status=="completed"):
		return false
	if not data.get("flags") is Dictionary or not data.flags.get("met_rowan") is bool or not data.get("areas") is Dictionary:
		return false
	for zone: Variant in data.areas:
		if not zone in ["dawn_village","whispering_forest"] or not data.areas[zone] is Dictionary:
			return false
		var area: Dictionary = data.areas[zone]
		if not _ids(area.get("collected")) or not _ids(area.get("defeated")) or not area.get("enemies") is Array or not area.get("drops") is Array or area.enemies.size()>32 or area.drops.size()>256:
			return false
		var seen: Dictionary = {}
		for enemy: Variant in area.enemies:
			if not enemy is Dictionary or not enemy.get("id") in ["scout_a","scout_b","guardian"] or seen.has(enemy.id) or not _point(enemy.get("at")) or not _integer(enemy.get("hp"),1,54) or area.defeated.has(enemy.id):
				return false
			seen[enemy.id] = true
		seen.clear()
		for drop: Variant in area.drops:
			if not drop is Dictionary or not drop.get("id") is String or drop.id.is_empty() or drop.id.length()>100 or seen.has(drop.id) or not items.has(drop.get("item")) or not _integer(drop.get("count"),1,99) or not _point(drop.get("at")) or drop.get("kind")!="drop":
				return false
			seen[drop.id] = true
	return true
