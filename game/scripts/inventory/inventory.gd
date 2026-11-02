extends RefCounted
signal changed
const CAPACITY: int = 16
var database: Dictionary = {}
var slots: Array = []

func _init() -> void:
	database = JSON.parse_string(FileAccess.get_file_as_string("res://resources/items/items.json"))
	clear()

func clear() -> void:
	slots.clear()
	for i: int in range(CAPACITY):
		slots.append({})
	changed.emit()

func count(id: String) -> int:
	var total: int = 0
	for slot: Dictionary in slots:
		if slot.get("id", "") == id:
			total += int(slot.count)
	return total

func room_for(id: String) -> int:
	if not database.has(id):
		return 0
	var room: int = 0
	for slot: Dictionary in slots:
		if slot.is_empty():
			room += int(database[id].max_stack)
		elif slot.id == id:
			room += int(database[id].max_stack)-int(slot.count)
	return room

func add(id: String, amount: int) -> int:
	if not database.has(id) or amount <= 0:
		return 0
	var left: int = amount
	for empty_pass: bool in [false, true]:
		for i: int in range(slots.size()):
			var slot: Dictionary = slots[i]
			if (empty_pass and slot.is_empty()) or (not empty_pass and slot.get("id", "") == id):
				var accepted: int = mini(left, int(database[id].max_stack)-int(slot.get("count",0)))
				if accepted > 0:
					slots[i] = {"id":id, "count":int(slot.get("count",0))+accepted}
					left -= accepted
	if left < amount:
		changed.emit()
	return amount-left

func remove(id: String, amount: int) -> bool:
	if amount <= 0 or count(id) < amount:
		return false
	var left: int = amount
	for i: int in range(slots.size()):
		if slots[i].get("id", "") == id:
			var taken: int = mini(left, int(slots[i].count))
			slots[i].count -= taken
			left -= taken
			if int(slots[i].count) == 0:
				slots[i] = {}
	changed.emit()
	return true

func use(index: int, health: Node) -> bool:
	if index < 0 or index >= slots.size() or slots[index].is_empty():
		return false
	var item: Dictionary = database[slots[index].id]
	if item.type != "consumable" or not health.heal(int(item.get("heal", 0))):
		return false
	return remove(str(slots[index].id),1)

func restore(data: Array) -> void:
	slots = data.duplicate(true)
	changed.emit()
