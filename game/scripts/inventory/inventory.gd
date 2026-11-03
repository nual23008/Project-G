extends RefCounted
signal changed
const CAPACITY: int = 16
const EQUIPMENT_SLOTS: Array[String] = ["hat","shirt","pants","shoe_left","shoe_right","necklace","bracelet_left","bracelet_right","glove_left","glove_right","weapon_left","weapon_right"]
const SLOT_NAMES: Array[String] = ["Mũ","Áo","Quần","Giày trái","Giày phải","Vòng cổ","Vòng tay trái","Vòng tay phải","Găng trái","Găng phải","Vũ khí trái","Vũ khí phải"]
const STARTER: Dictionary = {"hat":"traveler_hat","shirt":"indigo_coat","pants":"traveler_pants","shoe_left":"leather_boot","shoe_right":"leather_boot","necklace":"amber_necklace","bracelet_left":"copper_bracelet","bracelet_right":"copper_bracelet","glove_left":"leather_glove","glove_right":"leather_glove","weapon_left":"","weapon_right":""}
var equipment: Dictionary = {}
var last_error: String = ""
var database: Dictionary = {}
var slots: Array = []

func _init() -> void:
	database = JSON.parse_string(FileAccess.get_file_as_string("res://resources/items/items.json"))
	clear()

func clear() -> void:
	equipment.clear()
	for key: String in EQUIPMENT_SLOTS: equipment[key] = ""
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

func allowed(id: String, target: String) -> bool:
	return EQUIPMENT_SLOTS.has(target) and database.has(id) and target in database[id].get("allowed_slots",[])

func equip(index: int, target: String) -> bool:
	last_error = "Không thể mặc vật phẩm vào ô này."
	if index < 0 or index >= slots.size() or slots[index].is_empty(): return false
	var id: String = str(slots[index].id)
	if int(slots[index].get("count",0)) != 1 or not allowed(id,target): return false
	# Gear never stacks: the outgoing item takes the exact vacated bag cell.
	var outgoing: String = str(equipment[target])
	slots[index] = {} if outgoing.is_empty() else {"id":outgoing,"count":1}
	equipment[target] = id
	last_error = ""
	changed.emit()
	return true

func unequip(target: String) -> bool:
	last_error = "Ô trang bị đang trống."
	if not equipment.has(target) or str(equipment[target]).is_empty(): return false
	var empty: int = slots.find({})
	if empty < 0:
		last_error = "Túi đầy. Hãy tạo một ô trống trước khi tháo đồ."
		return false
	slots[empty] = {"id":str(equipment[target]),"count":1}
	equipment[target] = ""
	last_error = ""
	changed.emit()
	return true

func restore_equipment(data: Dictionary) -> bool:
	if not valid_equipment(data,database): return false
	equipment = data.duplicate(true)
	changed.emit()
	return true

static func valid_equipment(data: Variant, catalog: Dictionary) -> bool:
	if not data is Dictionary or data.size() != EQUIPMENT_SLOTS.size(): return false
	for key: String in EQUIPMENT_SLOTS:
		if not data.get(key) is String: return false
		var id: String = data[key]
		if not id.is_empty() and (not catalog.has(id) or not key in catalog[id].get("allowed_slots",[])): return false
	return true

func active_weapon() -> String:
	return str(equipment.weapon_right) if not str(equipment.weapon_right).is_empty() else str(equipment.weapon_left)

func weapon_damage() -> int:
	var id: String = active_weapon()
	return int(database[id].get("damage",0)) if not id.is_empty() else 0

func owned_count(id: String) -> int:
	return count(id)+equipment.values().count(id)

func equip_starter() -> void:
	equipment = STARTER.duplicate(true)
	for i: int in range(slots.size()):
		if slots[i].get("id","") == "rust_sword":
			equipment.weapon_right = "rust_sword"
			slots[i] = {}
			break
	changed.emit()
