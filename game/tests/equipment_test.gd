extends SceneTree
const INV := preload("res://scripts/inventory/inventory.gd")
const SAVE := preload("res://scripts/save/save_service.gd")
var checks: int = 0
var failures: int = 0
var main: Node

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, message: String) -> void:
	checks += 1
	if not value: failures += 1
	print("PASS: " if value else "FAIL: ",message)

func frames(count: int = 2) -> void:
	for i: int in range(count): await physics_frame
	await process_frame

func find_item(inventory: RefCounted,id: String) -> int:
	for i: int in range(inventory.slots.size()):
		if inventory.slots[i].get("id","") == id: return i
	return -1

func signature(value: Variant) -> String:
	return JSON.stringify(value).sha256_text()

func same_data(a: Variant,b: Variant) -> bool:
	if (a is int or a is float) and (b is int or b is float): return a == b
	if typeof(a) != typeof(b): return false
	if a is Dictionary:
		if a.size() != b.size(): return false
		for key: Variant in a:
			if not b.has(key) or not same_data(a[key],b[key]): return false
		return true
	if a is Array:
		if a.size() != b.size(): return false
		for i: int in range(a.size()):
			if not same_data(a[i],b[i]): return false
		return true
	return a == b

func write_envelope(path: String,version: int,data: Dictionary) -> void:
	var payload: String = JSON.stringify(data)
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify({"version":version,"payload":payload,"checksum":payload.sha256_text()}))
	file.close()

func run() -> void:
	var inventory: RefCounted = INV.new()
	check(inventory.equipment.size() == 12,"Exactly twelve independently owned equipment slots")
	for slot: String in INV.EQUIPMENT_SLOTS:
		var id: String = "rust_sword" if slot.begins_with("weapon") else str(INV.STARTER[slot])
		inventory.add(id,1)
		var count_before: int = inventory.owned_count(id)
		check(inventory.equip(find_item(inventory,id),slot),slot+": compatible item equips from a real bag cell")
		check(inventory.equipment[slot] == id and inventory.owned_count(id) == count_before,slot+": equip conserves ownership")
	for pair: Array in [["shoe_left","shoe_right"],["glove_left","glove_right"],["bracelet_left","bracelet_right"],["weapon_left","weapon_right"]]:
		var other: String = str(inventory.equipment[pair[1]])
		check(inventory.unequip(pair[0]) and inventory.equipment[pair[1]] == other,str(pair)+": removing left preserves right")
		var index: int = find_item(inventory,other)
		check(inventory.equip(index,pair[0]),str(pair)+": each side can be re-equipped independently")
	var before: String = signature({"bag":inventory.slots,"gear":inventory.equipment})
	check(not inventory.equip(-1,"hat") and not inventory.unequip("bad"),"Invalid indices and slot names are rejected")
	check(signature({"bag":inventory.slots,"gear":inventory.equipment}) == before,"Rejected transactions are atomic")
	inventory.add("potion",1)
	before = signature({"bag":inventory.slots,"gear":inventory.equipment})
	check(not inventory.equip(find_item(inventory,"potion"),"hat") and signature({"bag":inventory.slots,"gear":inventory.equipment}) == before,"Consumables cannot become equipment")
	inventory.add("steel_sword",1)
	inventory.add("rust_sword",16)
	before = signature({"bag":inventory.slots,"gear":inventory.equipment})
	check(not inventory.unequip("shirt") and signature({"bag":inventory.slots,"gear":inventory.equipment}) == before,"Full bag refuses unequip without losing any item")
	var slot0: String = str(inventory.slots[1].id)
	var rust_before: int = inventory.owned_count("rust_sword")
	var steel_before: int = inventory.owned_count("steel_sword")
	check(inventory.equip(1,"weapon_right") and inventory.slots[1].id == "rust_sword","Swapping equipment works even when the bag is full")
	check(inventory.owned_count("rust_sword") == rust_before and inventory.owned_count("steel_sword") == steel_before and slot0 == "steel_sword","Full-bag swap conserves distinct outgoing and incoming item counts")
	var bad: Dictionary = inventory.equipment.duplicate(true)
	bad.hat = "rust_sword"
	check(not inventory.restore_equipment(bad),"Incompatible equipment snapshots are rejected")
	bad = inventory.equipment.duplicate(true)
	bad.erase("shoe_right")
	check(not inventory.restore_equipment(bad),"Missing anatomical side cannot silently default")
	main = load("res://scenes/main/main.tscn").instantiate()
	main.save_path = "user://equipment_integration_only.json"
	root.add_child(main)
	main.start_game()
	await frames()
	check(main.world.player.has_method("set_equipment") and main.ui.has_signal("equip_requested"),"Fresh runtime includes the complete equipment API and UI signals")
	main.ui.ITEM_ART.clear()
	main.ui.update_inventory(main.inventory)
	check(main.ui.ITEM_ART.has("steel_sword") and main.ui.ITEM_ART.steel_sword != null,"Inventory rebuilds a missing steel sword icon cache at use without a Dictionary error")
	var complete_icons: bool = true
	for id: String in main.inventory.database:
		complete_icons = complete_icons and main.ui._item_art(id) != null
	check(complete_icons,"Every catalog item resolves its own animation even after the entire icon cache is cleared")
	var nearest_filters: bool = main.world.player.sprite.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST and main.ui.equipment_preview.base.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST
	for part: AnimatedSprite2D in main.world.player.equipment_visual.parts.values():
		nearest_filters = nearest_filters and part.texture_filter == CanvasItem.TEXTURE_FILTER_NEAREST
	check(nearest_filters,"Body, all equipment layers and bag preview use nearest filtering even under a linear parent viewport")
	var target := Node2D.new()
	target.position = main.world.player.position+Vector2(0,26)
	target.add_to_group("enemies")
	var health: Node = load("res://scripts/combat/health.gd").new()
	health.name = "Health"
	target.add_child(health)
	target.add_child(load("res://scripts/combat/hurtbox.gd").new())
	main.world.actors.add_child(target)
	await frames()
	main.world.player.facing = "down"
	check(main.world.player.empowered_attack(),"Swap fixture starts a real empowered swing before contact")
	var paid_energy: float = main.world.player.energy
	var paid_cooldown: float = main.world.player.cooldown
	main.open_hub()
	main.equip_item(find_item(main.inventory,"linen_tunic"),"hat")
	check(main.world.player.melee.remaining > 0 and main.world.player.state == main.world.player.State.ATTACK,"A rejected equipment transaction does not interrupt the existing swing")
	main.equip_item(find_item(main.inventory,"steel_sword"),"weapon_right")
	check(main.world.player.melee.remaining == 0 and not main.world.player.melee.visual.visible and main.world.player.state == main.world.player.State.IDLE,"Successful equipment change cancels the pending hit and old blade effect immediately")
	check(main.world.player.energy == paid_energy and main.world.player.cooldown == paid_cooldown,"Equipment interruption neither refunds mana nor bypasses cooldown")
	main.close_overlay()
	await frames(12)
	check(health.current == 100,"An interrupted swing cannot cause ghost damage after its old contact time")
	target.queue_free()
	main.open_hub()
	main.equip_item(find_item(main.inventory,"rust_sword"),"weapon_right")
	main.close_overlay()
	await frames(30)
	check(main.inventory.owned_count("rust_sword") == 1 and main.inventory.count("rust_sword") == 0 and main.world.player.weapon_damage == 18,"Starter sword is owned by the right hand, never duplicated in the bag")
	main.open_hub()
	check(main.ui.equipment_buttons.size() == 12 and main.ui.equipment_preview.loadout == main.inventory.equipment,"Bag exposes all twelve slots and an actual layered runtime preview")
	var overlapping: bool = false
	var buttons: Array = main.ui.equipment_buttons.values()
	for i: int in range(buttons.size()):
		for j: int in range(i+1,buttons.size()): overlapping = overlapping or buttons[i].get_global_rect().intersects(buttons[j].get_global_rect())
	check(not overlapping,"Equipment slot buttons remain separate with icons and long Vietnamese labels")
	var preview_frames: Dictionary = {}
	var paused_position: Vector2 = main.world.player.position
	for i: int in range(96):
		await frames(1)
		preview_frames[main.ui.equipment_preview.base.frame] = true
	check(preview_frames.size() >= 6 and main.world.player.position == paused_position,"Equipped avatar preview keeps animating while the bag pauses the world")
	for slot: String in INV.EQUIPMENT_SLOTS:
		var id: String = str(main.inventory.equipment[slot])
		if id.is_empty(): continue
		main.ui.select_equipment(slot)
		main.ui.unequip_button.pressed.emit()
		check(str(main.inventory.equipment[slot]).is_empty() and not main.world.player.equipment_visual.parts[slot].visible,slot+": UI unequip removes the actual worn sprite")
	var energy: float = main.world.player.energy
	main.close_overlay()
	check(main.world.player.weapon_damage == 0 and not main.world.player.empowered_attack() and main.world.player.energy == energy,"Both empty hands block a real slash before spending mana")
	main.open_hub()
	main.ui.select_slot(find_item(main.inventory,"rust_sword"))
	main.ui.select_equipment("weapon_left")
	main.ui.use_button.pressed.emit()
	check(main.inventory.equipment.weapon_left == "rust_sword" and main.world.player.weapon_damage == 18,"A left-hand weapon alone enables the real attack")
	main.ui.select_slot(find_item(main.inventory,"steel_sword"))
	main.ui.select_equipment("weapon_right")
	main.ui.use_button.pressed.emit()
	check(main.world.player.weapon_damage == 24,"Right-hand replacement drives damage from equipped data, not bag contents")
	main.ui.select_slot(find_item(main.inventory,"linen_tunic"))
	main.ui.select_equipment("shirt")
	main.ui.use_button.pressed.emit()
	check(main.inventory.equipment.shirt == "linen_tunic" and main.world.player.equipment_visual.parts.shirt.sprite_frames == load("res://resources/art/gear_linen_tunic_shirt.tres"),"Replacing clothing selects its own animated visual resource")
	main.close_overlay()
	for direction: String in main.world.player.FACING_NAMES:
		main.world.player.facing = direction
		for state: String in ["idle","walk","attack","hurt","death"]:
			var base: AnimatedSprite2D = main.world.player.sprite
			base.animation = state+"_"+direction
			base.pause()
			base.frame = 2
			main.world.player.equipment_visual.sync_pose()
			var matching: bool = true
			for part: AnimatedSprite2D in main.world.player.equipment_visual.parts.values():
				if part.visible: matching = matching and part.animation == base.animation and part.frame == 2 and part.offset == base.offset
			check(matching,direction+"/"+state+": worn layers share exact frame and pivot")
	# Let the real state machine regain ownership after the visual fixture.
	await frames()
	var snapshot: Dictionary = main.snapshot()
	var saves: RefCounted = SAVE.new()
	saves.path = "user://equipment_model_only.json"
	check(saves.valid_snapshot(snapshot) and saves.save_game(snapshot),"V3 saves twelve-slot equipment with the live world")
	var restored: Dictionary = saves.load_game()
	check(same_data(restored.equipment,snapshot.equipment) and same_data(restored.inventory,snapshot.inventory),"Save/load round trip preserves bag and equipped ownership")
	var raw: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(saves.path))
	check(raw.version == 3,"Equipment writes an explicit v3 envelope")
	bad = snapshot.duplicate(true)
	bad.equipment.shoe_left = "potion"
	check(not saves.valid_snapshot(bad),"Checksummed save cannot put a potion into a shoe slot")
	var legacy: Dictionary = snapshot.duplicate(true)
	legacy.erase("equipment")
	for i: int in range(legacy.inventory.size()):
		if not legacy.inventory[i].is_empty() and not str(legacy.inventory[i].id) in SAVE.LEGACY_ITEMS: legacy.inventory[i] = {}
	legacy.inventory[0] = {"id":"rust_sword","count":1}
	write_envelope(saves.path,2,legacy)
	var original: String = FileAccess.get_file_as_string(saves.path)
	restored = saves.load_game()
	check(not restored.is_empty() and restored.equipment.weapon_right == "rust_sword" and restored.progression == legacy.progression,"V2 migration equips its existing sword and preserves progression")
	check(FileAccess.get_file_as_string(saves.path) == original,"Loading V2 never rewrites the original save")
	write_envelope(saves.path,2,snapshot)
	check(saves.read_valid(saves.path).is_empty(),"A V3 payload disguised as V2 is rejected rather than duplicating gear")
	legacy.inventory[0] = {"id":"steel_sword","count":1}
	write_envelope(saves.path,2,legacy)
	check(saves.read_valid(saves.path).is_empty(),"V2 retains its original item catalog before migration")
	main.open_hub()
	main.ui.select_equipment("weapon_left")
	main.ui.unequip_button.pressed.emit()
	main.close_overlay()
	main.quests.record("npc_spoken","rowan")
	main.travel("whispering_forest")
	check(main.inventory.equipment.weapon_right == "steel_sword" and main.world.player.equipment_visual.loadout == main.inventory.equipment,"Area transition preserves the equipped outfit and real player visuals")
	main.open_hub()
	check(main.save_game() == false,"Saving remains limited to the system tab or live game")
	main.select_hub_tab(3)
	check(main.save_game() and main.load_game() and main.inventory.equipment.shirt == "linen_tunic","System tab restores the actual worn outfit through Main")
	main.queue_free()
	await process_frame
	paused = false
	print("EQUIPMENT_RESULT: ",checks-failures,"/",checks," checks passed")
	quit(0 if failures == 0 else 1)
