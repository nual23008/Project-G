extends Node

const WORLD_SCENE := preload("res://scenes/world/dawn_village.tscn")
const INPUT_SETUP := preload("res://scripts/core/input_setup.gd")
const DIALOGUE_SESSION := preload("res://scripts/dialogue/dialogue_session.gd")
const FOREST_SCENE := preload("res://scenes/world/whispering_forest.tscn")
const INVENTORY := preload("res://scripts/inventory/inventory.gd")
const QUESTS := preload("res://scripts/quests/quest_manager.gd")
const SAVES := preload("res://scripts/save/save_service.gd")
const RACES := preload("res://scripts/character/races.gd")
const PROGRESSION := preload("res://scripts/progression/progression.gd")
const EFFECT := preload("res://scripts/combat/sprite_effect.gd")
const LEVEL_UP: SpriteFrames = preload("res://resources/art/level_up.tres")
enum Mode { MENU, PLAYING, DIALOGUE, PAUSED, SETTINGS, INVENTORY_OPEN, JOURNAL, DEAD, CHARACTER, HUB_SYSTEM, RACE_SELECTION }
const ZOOM_LEVELS: Array[float] = [0.75, 1.0, 1.25, 1.5, 2.0]
var view_zoom: float = 1.0
var mode: Mode = Mode.MENU
var settings_return: Mode = Mode.MENU
var world: Node2D
var dialogue: RefCounted
var met_rowan: bool = false
var effects_enabled: bool = true
var inventory: RefCounted
var quests: RefCounted
var saves: RefCounted
var progression: RefCounted
var save_path: String = "user://journey.json"
var race_id: String = "human"
var zone: String = "dawn_village"
var areas: Dictionary = {}
@onready var ui: Control = $CanvasLayer/GameUI

func _ready() -> void:
	INPUT_SETUP.configure()
	add_child(preload("res://scripts/core/desktop_pointer.gd").new())
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_viewport().size_changed.connect(_apply_zoom)
	inventory = INVENTORY.new()
	quests = QUESTS.new()
	progression = PROGRESSION.new()
	progression.changed.connect(_on_progression_changed)
	progression.level_gained.connect(_on_level_gained)
	saves = SAVES.new()
	saves.path = save_path
	inventory.changed.connect(_refresh_inventory)
	quests.changed.connect(func() -> void: ui.update_quest(quests))
	quests.completed.connect(_reward_quest)
	dialogue = DIALOGUE_SESSION.new()
	dialogue.line_changed.connect(ui.show_line)
	dialogue.finished.connect(_dialogue_finished)
	ui.new_game_requested.connect(open_race_selection)
	ui.race_confirmed.connect(confirm_new_game)
	ui.race_cancelled.connect(cancel_race_selection)
	ui.resume_requested.connect(resume_game)
	ui.settings_requested.connect(open_settings)
	ui.settings_back_requested.connect(close_settings)
	ui.menu_requested.connect(return_to_menu)
	ui.quit_requested.connect(func() -> void: get_tree().quit())
	ui.dialogue_advance_requested.connect(advance_dialogue)
	ui.dialogue_choice_requested.connect(_choose_dialogue)
	ui.dialogue_close_requested.connect(close_dialogue)
	ui.effects_changed.connect(_set_effects)
	ui.continue_requested.connect(load_game)
	ui.save_requested.connect(save_game)
	ui.load_requested.connect(load_game)
	ui.overlay_close_requested.connect(close_overlay)
	ui.item_use_requested.connect(use_item)
	ui.respawn_requested.connect(respawn)
	ui.character_requested.connect(open_character)
	ui.allocate_stat_requested.connect(allocate_stat)
	ui.hub_requested.connect(open_hub)
	ui.hub_tab_requested.connect(select_hub_tab)
	ui.zoom_requested.connect(change_zoom)
	ui.equip_requested.connect(equip_item)
	ui.unequip_requested.connect(unequip_item)
	_replace_world(false)
	_refresh_inventory()
	ui.update_quest(quests)
	ui.update_progression(progression)
	ui.set_save_available(saves.has_save())
	_set_mode(Mode.MENU)

func _replace_world(playing: bool, next_zone: String = "dawn_village") -> void:
	if is_instance_valid(world):
		remove_child(world)
		world.queue_free()
	zone = next_zone
	world = (FOREST_SCENE if zone == "whispering_forest" else WORLD_SCENE).instantiate()
	world.content_state = areas.get(zone,{"collected":[],"defeated":[],"enemies":[],"drops":[]}).duplicate(true)
	world.process_mode = Node.PROCESS_MODE_PAUSABLE
	world.get_node("Actors/Player").race_id = race_id
	add_child(world)
	move_child(world, 0)
	world.player.visible = playing
	world.player.apply_stats(progression.derived_stats(), true)
	world.player.interaction.target_changed.connect(ui.set_prompt)
	world.player.health.changed.connect(ui.set_health)
	world.player.resources_changed.connect(ui.set_resources)
	world.player.action_failed.connect(ui.notify)
	world.player.fallen.connect(func() -> void: _set_mode(Mode.DEAD))
	world.enemy_defeated.connect(func(id: String) -> void: quests.record("enemy_defeated",id))
	world.experience_collected.connect(_gain_experience)
	world.open_gate(quests.status != "available")
	ui.location_label.text = "RỪNG THÌ THẦM\nVòng đá ở phía bắc • Lối về phía nam" if zone == "whispering_forest" else "LÀNG BÌNH MINH\nBình yên trong những khoảng quên"
	ui.set_health(world.player.hp,world.player.max_hp)
	ui.set_resources(world.player.energy, world.player.max_energy, world.player.stamina, world.player.max_stamina)
	world.get_node("Atmosphere").visible = effects_enabled
	if not playing:
		world.camera.position = Vector2(512, 400)
		world.camera.reset_smoothing()
	ui.set_prompt(null)
	_refresh_inventory()
	_apply_zoom()

func open_race_selection() -> void:
	if mode != Mode.MENU: return
	ui.select_race("human")
	_set_mode(Mode.RACE_SELECTION)

func cancel_race_selection() -> void:
	if mode == Mode.RACE_SELECTION: _set_mode(Mode.MENU)

func confirm_new_game(id: String) -> void:
	if mode == Mode.RACE_SELECTION and RACES.valid(id): start_game(id)

func start_game(id: String = "human") -> void:
	if not RACES.valid(id): return
	race_id = id
	dialogue.cancel()
	met_rowan = false
	areas.clear()
	progression.reset()
	inventory.clear()
	inventory.add("rust_sword",1)
	inventory.add("potion",3)
	inventory.equip_starter()
	inventory.add("steel_sword",1)
	inventory.add("linen_tunic",1)
	quests.restore({"status":"available","events":{},"reward_claimed":false})
	_replace_world(true)
	ui.set_met_rowan(false)
	ui.update_quest(quests)
	_set_mode(Mode.PLAYING)
	ui.notify("Bạn tỉnh dậy bên một ngôi làng lặng gió…")

func return_to_menu() -> void:
	dialogue.cancel()
	met_rowan = false
	_replace_world(false)
	ui.set_save_available(saves.has_save())
	_set_mode(Mode.MENU)

func _set_mode(next_mode: Mode) -> void:
	mode = next_mode
	get_tree().paused = mode != Mode.PLAYING
	world.player.input_enabled = mode == Mode.PLAYING
	world.player.stop()
	if mode not in [Mode.MENU,Mode.RACE_SELECTION]:
		world.snap_camera_to_player()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var screens: Dictionary = {Mode.MENU:"menu", Mode.PLAYING:"play", Mode.DIALOGUE:"dialogue", Mode.PAUSED:"pause", Mode.SETTINGS:"settings",Mode.INVENTORY_OPEN:"inventory",Mode.JOURNAL:"journal",Mode.DEAD:"death",Mode.CHARACTER:"character"}
	screens[Mode.HUB_SYSTEM] = "system"
	screens[Mode.RACE_SELECTION] = "race"
	ui.show_screen(screens[mode])

func pause_game() -> void:
	if mode == Mode.PLAYING:
		_set_mode(Mode.PAUSED)

func resume_game() -> void:
	if mode in [Mode.PAUSED,Mode.HUB_SYSTEM]:
		_set_mode(Mode.PLAYING)

func open_settings() -> void:
	if mode not in [Mode.MENU, Mode.PAUSED, Mode.HUB_SYSTEM]:
		return
	settings_return = mode
	_set_mode(Mode.SETTINGS)

func close_settings() -> void:
	if mode == Mode.SETTINGS:
		_set_mode(settings_return)

func interact() -> void:
	if mode != Mode.PLAYING:
		return
	if world.player.hp <= 0:
		return
	var target: Node2D = world.player.interaction.get_target()
	if target == null:
		return
	if target.has_method("interact_data"):
		_interact_object(target)
		return
	var id: String = str(target.dialogue_id)
	if id == "rowan" and quests.can_report():
		id = "rowan_return"
	if id.is_empty():
		return
	_set_mode(Mode.DIALOGUE)
	if not dialogue.start(id):
		_set_mode(Mode.PLAYING)

func advance_dialogue() -> void:
	if mode != Mode.DIALOGUE:
		return
	if ui.typing:
		ui.finish_typing()
	else:
		dialogue.advance()

func _choose_dialogue(index: int) -> void:
	if mode == Mode.DIALOGUE and not ui.typing:
		dialogue.choose(index)

func _dialogue_finished(id: String) -> void:
	if id == "rowan":
		met_rowan = true
		ui.set_met_rowan(true)
		ui.notify("Đã làm quen với Rowan. Hãy khám phá làng Bình Minh.")
	quests.record("npc_spoken",id)
	world.open_gate(quests.status != "available")
	ui.update_quest(quests)
	if id == "rowan" and quests.status == "active":
		ui.notify("Cổng bắc đã mở · E → Nhiệm vụ để xem mục tiêu.")
	_set_mode(Mode.PLAYING)

func close_dialogue() -> void:
	if mode == Mode.DIALOGUE:
		dialogue.cancel()
		_set_mode(Mode.PLAYING)

func _set_effects(enabled: bool) -> void:
	effects_enabled = enabled
	world.get_node("Atmosphere").visible = enabled

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.echo:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index in [MOUSE_BUTTON_WHEEL_UP,MOUSE_BUTTON_WHEEL_DOWN] and mode == Mode.PLAYING:
		change_zoom(1 if event.button_index == MOUSE_BUTTON_WHEEL_UP else -1)
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("fullscreen"):
		var full: bool = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if full else DisplayServer.WINDOW_MODE_FULLSCREEN)
		ui.sync_fullscreen()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("pause_game"):
		match mode:
			Mode.PLAYING: pause_game()
			Mode.PAUSED: resume_game()
			Mode.DIALOGUE: close_dialogue()
			Mode.SETTINGS: close_settings()
			Mode.RACE_SELECTION: cancel_race_selection()
			Mode.INVENTORY_OPEN, Mode.JOURNAL, Mode.CHARACTER, Mode.HUB_SYSTEM: close_overlay()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("interact"):
		if mode == Mode.PLAYING:
			if world.player.interaction.get_target() != null or not event is InputEventMouseButton:
				interact()
			else:
				world.player.empowered_attack(true)
		elif mode == Mode.DIALOGUE:
			advance_dialogue()
		get_viewport().set_input_as_handled()
	elif mode == Mode.DIALOGUE and event.is_action_pressed("ui_accept"):
		advance_dialogue()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("inventory"):
		if mode == Mode.PLAYING and world.player.hp>0:
			open_hub()
		elif mode in [Mode.INVENTORY_OPEN,Mode.CHARACTER,Mode.JOURNAL,Mode.HUB_SYSTEM]:
			close_overlay()
		elif mode == Mode.DIALOGUE:
			advance_dialogue()
		elif mode == Mode.SETTINGS and settings_return == Mode.HUB_SYSTEM:
			close_settings()
			close_overlay()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("journal"):
		if mode == Mode.PLAYING and world.player.hp>0:
			_set_mode(Mode.JOURNAL)
		elif mode == Mode.JOURNAL:
			close_overlay()
	elif event.is_action_pressed("attack") and mode == Mode.PLAYING:
		world.player.attack(event is InputEventMouseButton)
	elif event.is_action_pressed("empowered_attack") and mode == Mode.PLAYING:
		world.player.empowered_attack()
	elif event.is_action_pressed("character"):
		if mode == Mode.PLAYING:
			open_character()
		elif mode == Mode.CHARACTER:
			close_overlay()
	elif event.is_action_pressed("quick_heal") and mode == Mode.PLAYING:
		for i: int in range(inventory.slots.size()):
			if inventory.slots[i].get("id","") == "potion":
				use_item(i)
				break
	elif event.is_action_pressed("save_game") and mode in [Mode.PLAYING,Mode.PAUSED]:
		save_game()

func close_overlay() -> void:
	if mode in [Mode.INVENTORY_OPEN,Mode.JOURNAL,Mode.CHARACTER,Mode.HUB_SYSTEM]:
		_set_mode(Mode.PLAYING)

func open_hub() -> void:
	if mode == Mode.PLAYING and world.player.hp > 0:
		_set_mode(Mode.INVENTORY_OPEN)

func select_hub_tab(index: int) -> void:
	if mode in [Mode.INVENTORY_OPEN,Mode.CHARACTER,Mode.JOURNAL,Mode.HUB_SYSTEM] and index >= 0 and index < 4:
		_set_mode([Mode.INVENTORY_OPEN,Mode.CHARACTER,Mode.JOURNAL,Mode.HUB_SYSTEM][index])

func change_zoom(step: int) -> void:
	var index: int = ZOOM_LEVELS.find(view_zoom)
	view_zoom = ZOOM_LEVELS[clampi(index+step,0,ZOOM_LEVELS.size()-1)] if step != 0 else 1.0
	_apply_zoom()

func _apply_zoom() -> void:
	if not is_instance_valid(world):
		return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var minimum: float = maxf(viewport_size.x/(float(world.definition.width)*16.0),viewport_size.y/(float(world.definition.height)*16.0))
	world.camera.zoom = Vector2.ONE * maxf(view_zoom,minimum)
	ui.set_zoom(world.camera.zoom.x)

func open_character() -> void:
	if mode == Mode.PLAYING and world.player.hp > 0:
		ui.update_progression(progression)
		_set_mode(Mode.CHARACTER)

func allocate_stat(stat: String, amount: int) -> void:
	if mode == Mode.CHARACTER:
		if not progression.allocate(stat, amount):
			ui.notify("Không đủ điểm để tăng chỉ số này.")

func _on_progression_changed() -> void:
	ui.update_progression(progression)
	if is_instance_valid(world):
		world.player.apply_stats(progression.derived_stats())
		_refresh_inventory()

func _on_level_gained(_old_level: int, new_level: int, points: int) -> void:
	if is_instance_valid(world):
		EFFECT.spawn(world.actors, LEVEL_UP, world.player.global_position + Vector2(0,-18), Vector2(48,48))
	ui.notify("Lên cấp "+str(new_level)+"! +"+str(points)+" điểm · E → Nâng điểm.")

func _gain_experience(amount: int) -> void:
	if mode != Mode.PLAYING or world.player.hp <= 0:
		return
	var credited: int = roundi(amount * (1.0 + float(progression.derived_stats().xp_bonus)))
	var result: Dictionary = progression.gain_experience(credited)
	if progression.level == PROGRESSION.MAX_LEVEL and int(result.levels_gained) == 0:
		ui.notify("Đã đạt cấp 9999 · XP MAX.")
	elif int(result.levels_gained) == 0:
		ui.notify("+"+str(credited)+" kinh nghiệm")

func _refresh_inventory() -> void:
	ui.update_inventory(inventory,race_id)
	if is_instance_valid(world):
		world.player.weapon_damage = inventory.weapon_damage() + int(progression.derived_stats().damage_bonus) if inventory.weapon_damage()>0 else 0
		world.player.set_equipment(inventory.equipment)

func equip_item(index: int, slot: String) -> void:
	if mode != Mode.INVENTORY_OPEN: return
	if not inventory.equip(index,slot): ui.show_inventory_error(inventory.last_error)

func unequip_item(slot: String) -> void:
	if mode != Mode.INVENTORY_OPEN: return
	if not inventory.unequip(slot): ui.show_inventory_error(inventory.last_error)

func use_item(index: int) -> void:
	if mode not in [Mode.PLAYING,Mode.INVENTORY_OPEN]:
		return
	if inventory.use(index,world.player.health):
		ui.notify("Đã uống thuốc hồi phục.")
	else:
		ui.notify("Không thể dùng lúc này; thuốc không tiêu hao khi đầy HP.")

func _interact_object(object: Node2D) -> void:
	var data: Dictionary = object.interact_data()
	if data.kind == "portal":
		if zone == "dawn_village" and quests.status == "available":
			ui.notify("Hãy trò chuyện xong với Rowan để nhận việc và mở cổng.")
			return
		travel(str(data.destination))
		return
	if data.kind == "shard":
		quests.record("object_interacted",str(data.id))
		if not world.content_state.defeated.has(str(data.get("requires_defeated","guardian"))):
			ui.notify("Tinh thể bị sinh vật canh giữ. Hạ nó trước khi lấy mảnh dư âm.")
			return
	var item: String = str(data.item)
	var count: int = int(data.count)
	if inventory.room_for(item)<count:
		ui.notify("Túi đầy. Dùng bớt thuốc để tạo ô trống; vật phẩm vẫn ở đây.")
		return
	inventory.add(item,count)
	world.consume_object(object)
	quests.record("item_collected",item,count)
	ui.set_prompt(null)
	ui.notify("Đã nhận "+str(inventory.database[item].name)+" ×"+str(count))

func travel(destination: String) -> void:
	if mode != Mode.PLAYING or world.player.hp<=0 or not destination in ["dawn_village","whispering_forest"]:
		return
	areas[zone] = world.snapshot()
	var hp: int = world.player.hp
	var energy: float = world.player.energy
	var stamina: float = world.player.stamina
	if destination == "whispering_forest":
		_prepare_scout_respawns()
	_replace_world(true,destination)
	world.player.health.restore(hp)
	world.player.restore_vitals(energy, stamina)
	if destination == "dawn_village":
		world.player.position = Vector2(520,224)
		quests.record("area_entered","dawn_village_return")
	else:
		quests.record("area_entered",destination)
	world.player.health.immunity = 0.8
	world.snap_camera_to_player()
	_set_mode(Mode.PLAYING)
	world.modulate.a = 0.0
	world.create_tween().tween_property(world,"modulate:a",1.0,0.25)
	ui.notify("Đã đến "+str(world.definition.name))

func _prepare_scout_respawns() -> void:
	if not areas.has("whispering_forest"):
		return
	var state: Dictionary = areas.whispering_forest.duplicate(true)
	var cycles: Dictionary = state.get("spawn_cycles", {}).duplicate(true)
	for id: String in ["scout_a", "scout_b"]:
		if state.defeated.has(id) and int(cycles.get(id,0)) < 1000000000000:
			state.defeated.erase(id)
			cycles[id] = int(cycles.get(id,0)) + 1
	state.spawn_cycles = cycles
	areas.whispering_forest = state

func _reward_quest(rewards: Array) -> void:
	for i: int in range(rewards.size()):
		var reward: Dictionary = rewards[i]
		var accepted: int = inventory.add(str(reward.item),int(reward.count))
		if accepted<int(reward.count):
			world.drop_item(str(reward.item),int(reward.count)-accepted,world.player.position+Vector2(i*20,16),"quest_reward_"+str(i))
	ui.notify("Hoàn thành chặng thám hiểm! Nhận 2 thuốc và 3 quặng ký ức.")

func respawn() -> void:
	if mode != Mode.DEAD:
		return
	areas[zone] = world.snapshot()
	var previous_zone: String = zone
	_replace_world(true,"dawn_village")
	if previous_zone == "whispering_forest":
		quests.record("area_entered","dawn_village_return")
	world.player.health.restore(world.player.max_hp)
	world.player.restore_vitals(world.player.max_energy, world.player.max_stamina)
	_set_mode(Mode.PLAYING)
	ui.notify("Bạn tỉnh lại ở làng. Đồ đạc và tiến trình được giữ nguyên.")

func snapshot() -> Dictionary:
	areas[zone] = world.snapshot()
	return {"race":race_id,"zone":zone,"position":[world.player.position.x,world.player.position.y],"hp":world.player.hp,"inventory":inventory.slots.duplicate(true),"equipment":inventory.equipment.duplicate(true),"quest":quests.snapshot(),"flags":{"met_rowan":met_rowan},"areas":areas.duplicate(true),"progression":progression.snapshot(),"vitals":{"energy":world.player.energy,"stamina":world.player.stamina}}

func save_game() -> bool:
	if mode not in [Mode.PLAYING,Mode.PAUSED,Mode.HUB_SYSTEM] or world.player.hp<=0:
		return false
	var success: bool = saves.save_game(snapshot())
	var message: String = "Đã lưu hành trình. Có thể Tiếp tục từ màn hình chính." if success else saves.last_error
	ui.notify(message)
	ui.save_status.text = message
	ui.set_save_available(saves.has_save())
	return success

func load_game() -> bool:
	if mode not in [Mode.MENU,Mode.PAUSED,Mode.HUB_SYSTEM]:
		return false
	var data: Dictionary = saves.load_game()
	if data.is_empty():
		ui.save_status.text = saves.last_error
		ui.set_save_available(false)
		return false
	dialogue.cancel()
	if not progression.restore(data.progression):
		return false
	race_id = str(data.race)
	areas = data.areas.duplicate(true)
	met_rowan = bool(data.flags.met_rowan)
	inventory.restore(data.inventory)
	inventory.restore_equipment(data.equipment)
	quests.restore(data.quest)
	_replace_world(true,str(data.zone))
	world.player.position = Vector2(data.position[0],data.position[1])
	world.player.health.restore(int(data.hp))
	world.player.restore_vitals(float(data.vitals.energy), float(data.vitals.stamina))
	world.player.health.immunity = 0.8
	world.snap_camera_to_player()
	_set_mode(Mode.PLAYING)
	ui.notify("Đã khôi phục bản dự phòng hợp lệ." if saves.recovered_backup else "Đã tải hành trình.")
	return true
