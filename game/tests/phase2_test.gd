extends SceneTree
var checks: int = 0
var failures: Array[String] = []
var main: Node
var test_path: String = "user://phase2_automated_only.json"

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, text: String) -> void:
	checks += 1
	print("PASS: " if value else "FAIL: ",text)
	if not value:
		failures.append(text)

func frames(count: int = 2) -> void:
	for i: int in range(count):
		await physics_frame
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

func object(id: String) -> Node2D:
	for node: Node in main.world.actors.get_children():
		if node.has_method("interact_data") and node.object_id == id and not node.is_queued_for_deletion():
			return node
	return null

func enemy(id: String) -> CharacterBody2D:
	for node: Node in main.world.actors.get_children():
		if node.is_in_group("enemies") and node.enemy_id == id and not node.is_queued_for_deletion():
			return node
	return null

func take(id: String) -> void:
	var target: Node2D = object(id)
	if target == null:
		check(false,"Object exists: "+id)
		return
	main.world.player.position = target.position+Vector2(0,22)
	await frames()
	await key(KEY_E)
	await frames()

func finish_rowan() -> void:
	main.world.player.position = Vector2(548,421)
	await frames()
	await key(KEY_E)
	if main.dialogue.current_id=="rowan":
		main.ui.finish_typing()
		main.advance_dialogue()
		main.ui.finish_typing()
		main.advance_dialogue()
		main.ui.finish_typing()
		main.dialogue.choose(2)
	main.ui.finish_typing()
	main.advance_dialogue()
	await frames()

func run() -> void:
	# Only dedicated test files are removed. Never touches user://journey.json.
	for suffix: String in ["",".bak",".tmp",".bak.tmp"]:
		if FileAccess.file_exists(test_path+suffix):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path+suffix))
	main = load("res://scenes/main/main.tscn").instantiate()
	main.save_path = test_path
	root.add_child(main)
	await frames()
	check(main.ui.continue_button.disabled,"Continue disabled without valid test save")
	main.start_game()
	check(main.inventory.count("potion")==3 and main.inventory.count("rust_sword")==1,"New journey grants real usable starter items")
	var before: int = main.inventory.count("potion")
	await key(KEY_H)
	check(main.inventory.count("potion")==before,"Full-health potion is not consumed")
	check(main.world.player.health.damage(45,Vector2.RIGHT),"Player receives damage")
	check(not main.world.player.health.damage(45,Vector2.RIGHT),"Invulnerability blocks immediate repeat damage")
	check(main.ui.hp_label.text=="55 / 100","HUD follows actual health signal")
	await key(KEY_H)
	check(main.world.player.hp==95 and main.inventory.count("potion")==2,"H consumes a potion and heals 40 HP")
	await key(KEY_I)
	check(main.mode==main.Mode.INVENTORY_OPEN and paused,"I opens real inventory and pauses world")
	var pos: Vector2 = main.world.player.position
	Input.action_press("move_right")
	await key(KEY_J)
	await frames(12)
	Input.action_release("move_right")
	check(main.world.player.position==pos and main.world.player.melee.remaining<=0,"Inventory blocks movement and attacks")
	main.ui.item_use_requested.emit(1)
	check(main.world.player.hp==100 and main.inventory.count("potion")==1,"Inventory Use button consumes selected potion")
	await key(KEY_ESCAPE)
	await key(KEY_Q)
	check(main.mode==main.Mode.JOURNAL and main.ui.journal_text.text.contains("Dư Âm"),"Q opens journal with quest data")
	await key(KEY_ESCAPE)
	# Stand at gate; without finishing Rowan, travel is blocked.
	main.world.player.position = Vector2(520,200)
	await frames()
	await key(KEY_E)
	check(main.zone=="dawn_village","Forest portal requires accepted quest")
	await finish_rowan()
	check(main.quests.status=="active" and main.met_rowan,"Finishing Rowan dialogue accepts quest")
	main.world.player.position = Vector2(520,200)
	await frames()
	await key(KEY_E)
	check(main.zone=="whispering_forest" and main.world.player.hp==100,"Portal loads forest and preserves HP")
	check(main.quests.done(0),"Area event advances quest")
	check(enemy("guardian")!=null and enemy("scout_a")!=null,"Authored guardian and patrollers spawn")
	var scout: CharacterBody2D = enemy("scout_a")
	var origin: Vector2 = scout.position
	await frames(45)
	check(scout.position.distance_to(origin)>3,"Patrol moves along a deliberate route")
	main.world.player.position = scout.position+Vector2(0,70)
	await frames(3)
	check(scout.state==scout.State.CHASE,"Enemy detects player and chases")
	main.world.player.position = Vector2(512,680)
	await frames(30)
	check(scout.state in [scout.State.RETURN,scout.State.PATROL],"Enemy disengages and returns when player leaves leash")
	# Stand within range without attacking: telegraph must lead to real damage.
	main.world.player.position = scout.position+Vector2(0,18)
	main.world.player.health.immunity = 0
	main.world.player.health.restore(100)
	var saw_windup: bool = false
	for i: int in range(110):
		saw_windup = saw_windup or scout.state==scout.State.WINDUP
		await frames(1)
	check(saw_windup and main.world.player.hp<100,"Enemy telegraph leads to real melee damage")
	check(main.world.player.hp>=72,"Enemy cooldown prevents damage every frame")
	main.world.player.health.restore(100)
	await take("forest_chest")
	check(main.inventory.count("potion")==3 and object("forest_chest")==null,"Chest adds items once and disappears")
	await take("herb_a")
	check(main.inventory.count("herb")==3,"World resource pickup adds stack")
	var held_slots: Array = main.inventory.slots.duplicate(true)
	main.inventory.clear()
	main.inventory.add("rust_sword",16)
	await take("herb_b")
	check(object("herb_b")!=null and main.inventory.count("herb")==0,"Full inventory leaves pickup intact in world")
	main.inventory.restore(held_slots)
	await take("ancient_shard")
	check(main.inventory.count("echo_shard")==0 and main.quests.done(1),"Finding shard advances quest but guardian protects pickup")
	# Real hitbox/hurtbox battle, not Health.damage or an emitted kill signal.
	var guardian: CharacterBody2D = enemy("guardian")
	main.world.player.health.restore(100)
	main.world.player.position = guardian.position+Vector2(0,28)
	main.world.player.facing = "up"
	await frames()
	await key(KEY_J)
	await frames(9)
	check(guardian.health.current==36,"Keyboard melee deals data-defined weapon damage through hurtbox")
	check(not main.world.player.attack(),"Attack cooldown rejects spam")
	check(main.save_game(),"Mid-combat state can be saved")
	main.pause_game()
	check(main.load_game(),"Mid-combat save reloads")
	await frames(2)
	guardian = enemy("guardian")
	check(guardian.health.current==36 and object("forest_chest")==null,"Load preserves damaged enemy HP and opened chest")
	await frames(35)
	var attacks: int = 0
	while enemy("guardian")!=null and attacks<8:
		guardian = enemy("guardian")
		main.world.player.position = guardian.position+Vector2(0,28)
		main.world.player.facing = "up"
		await key(KEY_J)
		await frames(37)
		attacks += 1
	check(enemy("guardian")==null and main.quests.done(2),"Actual melee defeat emits quest event")
	check(object("guardian_loot_0")!=null,"Defeated enemy drops real pickup objects")
	await take("guardian_loot_0")
	check(main.inventory.count("ore")==2,"Enemy loot is collected into inventory")
	await take("ancient_shard")
	check(main.inventory.count("echo_shard")==1 and main.quests.done(3),"Shard becomes collectible after guardian defeat")
	# Death, animation and respawn preserve world progress without writing save.
	main.world.player.health.immunity = 0
	main.world.player.health.damage(1000,Vector2.ZERO)
	await frames(65)
	check(main.mode==main.Mode.DEAD and main.world.player.sprite.animation.begins_with("death"),"Death animation ends at respawn screen")
	main.ui.respawn_requested.emit()
	await frames()
	check(main.zone=="dawn_village" and main.world.player.hp==100 and main.inventory.count("echo_shard")==1,"Respawn keeps items and returns to village at full HP")
	# Reenter/back using portals, checking killed enemies and chests persist.
	main.travel("whispering_forest")
	await frames()
	check(enemy("guardian")==null and object("forest_chest")==null and object("ancient_shard")==null,"Zone reload preserves guardian, chest and shard state")
	await take("return_village")
	check(main.zone=="dawn_village" and main.quests.done(4),"Return portal records the journey home")
	await finish_rowan()
	check(main.quests.status=="completed" and main.quests.reward_claimed,"Report to Rowan completes quest and claims reward")
	var reward_count: int = main.inventory.count("ore")
	await finish_rowan()
	check(main.inventory.count("ore")==reward_count,"Repeated NPC conversation never duplicates reward")
	main.world.player.health.restore(73)
	main.world.player.position = Vector2(536,445)
	check(main.save_game(),"Valid snapshot saves atomically")
	check(main.ui.continue_button.disabled==false,"Valid save enables Continue")
	var snapshot: Dictionary = main.saves.load_game()
	check(snapshot.hp==73 and snapshot.quest.status=="completed","Save contains actual HP and quest progress")
	main.start_game()
	main.return_to_menu()
	check(main.load_game(),"Continue reloads saved journey")
	check(main.world.player.hp==73 and main.world.player.position==Vector2(536,445) and main.inventory.count("echo_shard")==1 and main.quests.status=="completed","Load restores position, health, inventory and quest together")
	main.travel("whispering_forest")
	await frames()
	check(enemy("guardian")==null and object("forest_chest")==null,"Saved world state survives new game and reload")
	check(object("guardian_loot_1")!=null,"Uncollected enemy loot survives save/load")
	# A second successful save creates a recoverable backup.
	check(main.save_game(),"Second save rotates a valid backup")
	var saved_raw: String = FileAccess.get_file_as_string(test_path)
	var file := FileAccess.open(test_path,FileAccess.WRITE)
	file.store_string("{broken json")
	file.close()
	check(not main.saves.load_game().is_empty() and main.saves.recovered_backup,"Corrupt primary falls back to verified backup")
	file = FileAccess.open(test_path,FileAccess.WRITE)
	file.store_string(saved_raw)
	file.close()
	var bad: Dictionary = snapshot.duplicate(true)
	bad.inventory[0] = {"id":"potion","count":999}
	check(not main.saves.save_game(bad) and FileAccess.get_file_as_string(test_path)==saved_raw,"Invalid inventory cannot overwrite valid save")
	bad = snapshot.duplicate(true)
	bad.position = [NAN,50]
	check(not main.saves.valid_snapshot(bad),"Non-finite positions rejected")
	var envelope: Dictionary = JSON.parse_string(saved_raw)
	envelope.version = 900
	file = FileAccess.open(test_path+".tmp",FileAccess.WRITE)
	file.store_string(JSON.stringify(envelope))
	file.close()
	check(main.saves.read_valid(test_path+".tmp").is_empty(),"Unsupported save version rejected")
	envelope = JSON.parse_string(saved_raw)
	envelope.payload = str(envelope.payload)+" "
	file = FileAccess.open(test_path+".tmp",FileAccess.WRITE)
	file.store_string(JSON.stringify(envelope))
	file.close()
	check(main.saves.read_valid(test_path+".tmp").is_empty(),"Checksum rejects payload corruption")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path+".tmp"))
	DirAccess.make_dir_absolute(ProjectSettings.globalize_path(test_path+".tmp"))
	check(not main.saves.save_game(snapshot) and FileAccess.get_file_as_string(test_path)==saved_raw,"Failed temp write leaves valid primary unchanged")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(test_path+".tmp"))
	# Capacity and stack boundaries: no silent loss when inventory is full.
	var inv: RefCounted = load("res://scripts/inventory/inventory.gd").new()
	check(inv.add("herb",25)==25 and inv.slots[0].count==20 and inv.slots[1].count==5,"Stack limit splits resources across slots")
	inv.clear()
	check(inv.add("rust_sword",17)==16 and inv.room_for("echo_shard")==0,"Inventory capacity rejects overflow accurately")
	check(not inv.remove("rust_sword",17) and inv.count("rust_sword")==16,"Failed removal never partially consumes")
	print("RESULT: ",checks-failures.size(),"/",checks," phase2 checks passed")
	paused = false
	main.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
