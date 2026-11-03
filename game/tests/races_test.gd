extends SceneTree
const RACES := preload("res://scripts/character/races.gd")
const INV := preload("res://scripts/inventory/inventory.gd")
var checks: int = 0
var failures: int = 0
var main: Node
const PATH := "user://races_integration_only.json"

func _initialize() -> void: call_deferred("run")
func check(ok: bool, note: String) -> void:
	checks += 1
	if not ok: failures += 1
	print("PASS: " if ok else "FAIL: ",note)
func frames(n: int = 3) -> void:
	for i: int in range(n): await physics_frame
	await process_frame
func key(code: Key) -> void:
	var e := InputEventKey.new()
	e.keycode = code
	e.physical_keycode = code
	e.pressed = true
	Input.parse_input_event(e)
	await frames(1)
	e = e.duplicate()
	e.pressed = false
	Input.parse_input_event(e)
	await frames(1)
func write_envelope(path: String, version: int, data: Dictionary) -> void:
	var payload: String = JSON.stringify(data)
	var f := FileAccess.open(path,FileAccess.WRITE)
	f.store_string(JSON.stringify({"version":version,"payload":payload,"checksum":payload.sha256_text()}))
	f.close()
func signature(data: Dictionary) -> String: return JSON.stringify(data)
func find_item(id: String) -> int:
	for i: int in range(16):
		if main.inventory.slots[i].get("id","") == id: return i
	return -1

func run() -> void:
	for suffix: String in ["",".bak",".tmp",".bak.tmp"]:
		if FileAccess.file_exists(PATH+suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH+suffix))
	main = load("res://scenes/main/main.tscn").instantiate()
	main.save_path = PATH
	root.add_child(main)
	await frames()
	main.ui.new_button.pressed.emit()
	check(main.mode == main.Mode.RACE_SELECTION and paused,"New game pauses the world and opens race selection")
	check(main.ui.race_buttons.size() == 4 and main.ui.race_buttons.human.has_focus(),"Four choices and initial keyboard focus")
	var observed: Dictionary = {}
	for id: String in RACES.IDS: observed[id] = {}
	for i: int in range(110):
		await frames(1)
		for id: String in RACES.IDS: observed[id][main.ui.race_thumbnails[id].frame] = true
	for id: String in RACES.IDS: check(observed[id].size() > 2,id+": thumbnail animates without interaction in the paused menu")
	await key(KEY_ESCAPE)
	check(main.mode == main.Mode.MENU and main.ui.new_button.has_focus(),"Escape cancels selection and restores menu focus")
	main.start_game("orc")
	main.inventory.add("ore",2)
	main.world.player.health.restore(73)
	main.return_to_menu()
	var before: String = signature(main.snapshot())
	main.open_race_selection()
	main.ui.race_buttons.elf.pressed.emit()
	main.ui.race_cancelled.emit()
	check(main.race_id == "orc" and signature(main.snapshot()) == before,"Choosing then cancelling preserves race, bag, HP, quest and world state")
	main.confirm_new_game("elf")
	check(main.mode == main.Mode.MENU and main.race_id == "orc","Confirmation outside the selection screen is ignored")
	for id: String in RACES.IDS:
		main.open_race_selection()
		main.ui.race_buttons[id].pressed.emit()
		check(main.ui.selected_race == id and main.ui.race_buttons[id].button_pressed,id+": real card selects its own identity")
		for state_index: int in range(5):
			for dir_index: int in range(8):
				main.ui.set_race_pose(state_index,dir_index)
				check(main.ui.race_preview.animation == main.ui.RACE_STATES[state_index]+"_"+main.ui.RACE_DIRECTIONS[dir_index],id+": preview "+str(state_index)+" / "+str(dir_index))
		main.ui.race_confirm.grab_focus()
		await key(KEY_ENTER)
		check(main.mode == main.Mode.PLAYING and main.race_id == id and main.world.player.race_id == id,id+": keyboard confirmation creates the selected playable race")
		check(main.ui.race_preview.sprite_frames == null,id+": full menu showcase released while playing")
		check(main.world.player.sprite.sprite_frames.resource_path == RACES.frames(id,"player").resource_path,id+": runtime body uses its own registered atlas")
		check(main.world.player.equipment_visual.race_id == id and main.ui.equipment_preview.race_id == id,id+": world and bag use the same anatomy")
		check(main.world.player.walk_speed == 72 and main.world.player.run_speed == 112 and main.world.player.hp == 100,id+": shared starting gameplay values")
		var player: CharacterBody2D = main.world.player
		for direction: String in ["up","up_left","up_right","left","right","down"]:
			player.sprite.animation = "idle_"+direction
			player.equipment_visual.sync_pose(true)
			var blade: AnimatedSprite2D = player.equipment_visual.parts.weapon_right
			check(blade.get_parent() == player.sprite and blade.z_index == 0 and blade.show_behind_parent == (direction.begins_with("up") or direction=="left"),id+": blade occlusion is local to the body, preserving terrain/UI and Y-sort / "+direction)
		var start: Vector2 = player.position
		Input.action_press("move_up")
		await frames(12)
		Input.action_release("move_up")
		check(player.position.y < start.y-10 and player.sprite.animation == "walk_up",id+": real input moves north with the full rear animation")
		await frames(3)
		player.facing = "down_right"
		check(player.attack(),id+": starter blade can attack")
		await frames(5)
		check(player.melee.weapon_contact_tip == Vector2(RACES.contacts(id).down_right.weapon_right[0],RACES.contacts(id).down_right.weapon_right[1]),id+": VFX contact comes from this race's weapon tip")
		await frames(20)
		main.open_hub()
		for slot: String in INV.EQUIPMENT_SLOTS:
			var item: String = str(main.inventory.equipment[slot])
			if item.is_empty(): continue
			main.ui.select_equipment(slot)
			main.ui.unequip_button.pressed.emit()
			check(main.inventory.equipment[slot].is_empty() and not player.equipment_visual.parts[slot].visible,id+": remove "+slot)
			main.ui.select_slot(find_item(item))
			main.ui.select_equipment(slot)
			main.ui.use_button.pressed.emit()
			check(main.inventory.equipment[slot] == item and player.equipment_visual.parts[slot].visible,id+": re-equip "+slot)
		check(player.equipment_visual.parts.heritage.visible == (id != "human"),id+": natural traits remain independent from equipment")
		main.ui.select_slot(find_item("steel_sword"))
		main.ui.select_equipment("weapon_left")
		main.ui.use_button.pressed.emit()
		check(main.inventory.equipment.weapon_left == "steel_sword" and player.equipment_visual.parts.weapon_left.sprite_frames == RACES.frames(id,"gear_steel_sword_weapon_left"),id+": left-hand replacement loads this race's own blade cels")
		main.ui.select_slot(find_item("linen_tunic"))
		main.ui.select_equipment("shirt")
		main.ui.use_button.pressed.emit()
		check(main.inventory.equipment.shirt == "linen_tunic" and main.ui.equipment_preview.parts.shirt.sprite_frames == RACES.frames(id,"gear_linen_tunic_shirt"),id+": replacement tunic and preview use this race's own joints")
		main.unequip_item("weapon_right")
		main.close_overlay()
		await frames(4)
		check(player.attack() and player.weapon_damage == 24,id+": a left-hand steel blade alone enables the actual attack")
		await frames(5)
		check(player.melee.weapon_contact_tip == Vector2(RACES.contacts(id).down_right.weapon_left[0],RACES.contacts(id).down_right.weapon_left[1]),id+": left-hand contact matches its own cel")
		await frames(20)
		check(main.save_game(),id+": race saves through the real game flow")
		var raw: String = FileAccess.get_file_as_string(PATH)
		var envelope: Dictionary = JSON.parse_string(raw)
		check(envelope.version == 4 and JSON.parse_string(envelope.payload).race == id,id+": explicit v4 identity")
		main.return_to_menu()
		check(main.load_game() and main.race_id == id and main.world.player.race_id == id and main.ui.equipment_preview.race_id == id,id+": load restores body, gear and bag preview")
		check(FileAccess.get_file_as_string(PATH) == raw,id+": loading is read-only")
		main.quests.record("npc_spoken","rowan")
		main.travel("whispering_forest")
		await frames(2)
		check(main.world.player.race_id == id and main.race_id == id,id+": area travel keeps race")
		main.world.player.health.immunity = 0.0
		main.world.player.health.damage(1000,Vector2.ZERO)
		await frames(60)
		check(main.mode == main.Mode.DEAD,id+": death animation completes")
		main.respawn()
		check(main.world.player.race_id == id and main.race_id == id and main.world.player.hp == 100,id+": respawn keeps race")
		main.return_to_menu()
	# Original v3 schema is validated before adding a human identity in memory.
	main.start_game("elf")
	var current: Dictionary = main.snapshot()
	var v3: Dictionary = current.duplicate(true)
	v3.erase("race")
	write_envelope(PATH,3,v3)
	var v3_raw: String = FileAccess.get_file_as_string(PATH)
	check(main.saves.read_valid(PATH).race == "human" and main.saves.has_save() and FileAccess.get_file_as_string(PATH) == v3_raw,"V3 migration defaults to human without writing or rotating its original bytes")
	for legacy_version: int in [1,2,3]:
		write_envelope(PATH,legacy_version,current)
		check(main.saves.read_valid(PATH).is_empty(),"Race field is reserved against disguised v"+str(legacy_version)+" envelopes")
	for invalid: Variant in ["dwraf","unknown","",1,null,{},true]:
		var bad: Dictionary = current.duplicate(true)
		bad.race = invalid
		write_envelope(PATH,4,bad)
		check(main.saves.read_valid(PATH).is_empty() and not main.saves.valid_snapshot(bad),"Invalid race is rejected: "+str(invalid))
	write_envelope(PATH,4,v3)
	check(main.saves.read_valid(PATH).is_empty(),"V4 may not silently default a missing race")
	write_envelope(PATH,4,current)
	write_envelope(PATH+".bak",4,current)
	var bad: Dictionary = current.duplicate(true)
	bad.race = "unknown"
	write_envelope(PATH,4,bad)
	check(main.saves.load_game().race == "elf" and main.saves.recovered_backup,"Invalid race triggers verified backup recovery")
	main.queue_free()
	await process_frame
	paused = false
	for suffix: String in ["",".bak",".tmp",".bak.tmp"]:
		if FileAccess.file_exists(PATH+suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH+suffix))
	print("RACES_RESULT: ",checks-failures,"/",checks," checks passed")
	quit(1 if failures else 0)
