extends RefCounted
## Dialogue graph logic independent of UI or world. Content can be extended via JSON.
signal line_changed(speaker: String, role: String, text: String, choices: Array, portrait: String)
signal finished(dialogue_id: String)

var database: Dictionary = {}
var current_id: String = ""
var current_node: String = ""
var active: bool = false

func _init() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://resources/dialogue/rowan.json"))
	if parsed is Dictionary:
		database = parsed
	else:
		push_error("Dialogue database is invalid.")

func start(id: String) -> bool:
	if not database.has(id):
		return false
	current_id = id
	current_node = str(database[id].get("start", ""))
	active = true
	return _publish()

func advance() -> void:
	if not active:
		return
	var node: Dictionary = database[current_id].nodes[current_node]
	if not node.get("choices", []).is_empty():
		return
	current_node = str(node.get("next", ""))
	_publish()

func choose(index: int) -> void:
	if not active:
		return
	var choices: Array = database[current_id].nodes[current_node].get("choices", [])
	if index < 0 or index >= choices.size():
		return
	current_node = str(choices[index].get("next", ""))
	_publish()

func cancel() -> void:
	active = false
	current_node = ""
	current_id = ""

func _publish() -> bool:
	if current_node.is_empty():
		active = false
		finished.emit(current_id)
		return true
	var entry: Dictionary = database[current_id]
	if not entry.nodes.has(current_node):
		push_error("Unknown dialogue node: " + current_node)
		active = false
		finished.emit(current_id)
		return false
	var node: Dictionary = entry.nodes[current_node]
	line_changed.emit(str(entry.name), str(entry.get("role", "")), str(node.text), node.get("choices", []), str(entry.get("portrait", "")))
	return true
