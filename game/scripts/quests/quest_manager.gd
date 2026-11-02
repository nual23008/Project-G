extends RefCounted
signal changed
signal completed(rewards: Array)
var definition: Dictionary = {}
var status: String = "available"
var events: Dictionary = {}
var reward_claimed: bool = false

func _init() -> void:
	definition = JSON.parse_string(FileAccess.get_file_as_string("res://resources/quests/first_echo.json"))

func record(event: String, target: String, amount: int = 1) -> void:
	if event == "npc_spoken" and target == "rowan" and status == "available":
		status = "active"
	if status != "active":
		return
	# Record only declared objectives; earlier kills remain valid when found out of order.
	for objective: Dictionary in definition.objectives:
		if objective.event == event and objective.target == target:
			var key: String = event+":"+target
			events[key] = mini(int(objective.count), int(events.get(key, 0))+maxi(0,amount))
	if ready_to_finish():
		status = "completed"
		if not reward_claimed:
			reward_claimed = true
			completed.emit(definition.rewards)
	changed.emit()

func done(index: int) -> bool:
	var objective: Dictionary = definition.objectives[index]
	return int(events.get(str(objective.event)+":"+str(objective.target),0)) >= int(objective.count)

func ready_to_finish() -> bool:
	for i: int in range(definition.objectives.size()):
		if not done(i):
			return false
	return true

func can_report() -> bool:
	if status != "active":
		return false
	for i: int in range(definition.objectives.size()-1):
		if not done(i):
			return false
	return true

func objective_text() -> String:
	if status == "available":
		return "Trò chuyện với Rowan ở quảng trường"
	if status == "completed":
		return "Đã báo tin · Chặng tiếp: Lyra (Phase 3)"
	for i: int in range(definition.objectives.size()):
		if not done(i):
			return str(definition.objectives[i].text)
	return "Báo tin cho Rowan"

func snapshot() -> Dictionary:
	return {"status":status,"events":events.duplicate(),"reward_claimed":reward_claimed}

func restore(data: Dictionary) -> void:
	status = str(data.status)
	events = data.events.duplicate()
	reward_claimed = bool(data.reward_claimed)
	changed.emit()
