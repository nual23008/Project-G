extends "res://tests/phase2_test.gd"
## Bot uses movement inputs and real combat/potions through the whole authored route.
## It does not teleport, inject damage, kill flags, inventory rewards or quest events.

func move_input(direction: Vector2) -> void:
	for action: String in ["move_left","move_right","move_up","move_down"]:
		Input.action_release(action)
	if direction.x>0.25: Input.action_press("move_right")
	if direction.x< -0.25: Input.action_press("move_left")
	if direction.y>0.25: Input.action_press("move_down")
	if direction.y< -0.25: Input.action_press("move_up")

func walk_to(goal: Vector2) -> bool:
	for tick: int in range(3600):
		var player: CharacterBody2D = main.world.player
		if player.hp<=0:
			move_input(Vector2.ZERO)
			return false
		var nearest: CharacterBody2D = null
		var distance: float = 77
		for node: Node in main.world.actors.get_children():
			if node.is_in_group("enemies") and not node.is_queued_for_deletion() and player.position.distance_to(node.position)<distance:
				nearest = node
				distance = player.position.distance_to(node.position)
		if player.hp<60:
			for i: int in range(main.inventory.slots.size()):
				if main.inventory.slots[i].get("id","")=="potion":
					main.use_item(i)
					break
		if nearest!=null:
			var aim: Vector2 = (nearest.position-player.position).normalized()
			player.facing = ("right" if aim.x>0 else "left") if absf(aim.x)>absf(aim.y) else ("down" if aim.y>0 else "up")
			if distance<33:
				move_input(Vector2.ZERO)
				player.attack()
			else:
				move_input((main.world.next_step(player.position,nearest.position)-player.position).normalized())
		else:
			if player.position.distance_to(goal)<7:
				move_input(Vector2.ZERO)
				await frames(2)
				return true
			move_input((main.world.next_step(player.position,goal)-player.position).normalized())
		await frames(1)
	move_input(Vector2.ZERO)
	print("STUCK: goal=",goal," position=",main.world.player.position)
	return false

func run() -> void:
	test_path = "user://phase2_journey_only.json"
	main = load("res://scenes/main/main.tscn").instantiate()
	main.save_path = test_path
	root.add_child(main)
	main.start_game()
	check(await walk_to(Vector2(548,421)),"Walk from spawn to Rowan without teleport")
	await key(KEY_E)
	main.ui.finish_typing()
	main.advance_dialogue()
	main.ui.finish_typing()
	main.advance_dialogue()
	main.ui.finish_typing()
	main.dialogue.choose(2)
	main.ui.finish_typing()
	main.advance_dialogue()
	check(main.quests.status=="active","Route accepts Rowan quest through dialogue")
	check(await walk_to(Vector2(520,200)),"Walk to north gate without teleport")
	await key(KEY_E)
	check(main.zone=="whispering_forest","Route enters forest using E portal")
	check(await walk_to(Vector2(512,306)),"Traverse forest and survive actual enemy battles without injected damage or HP")
	await key(KEY_E)
	check(main.inventory.count("echo_shard")==1 and main.quests.done(2),"Route defeats guardian and picks up quest crystal")
	check(await walk_to(Vector2(512,668)),"Walk back through forest to exit")
	await key(KEY_E)
	check(main.zone=="dawn_village","Route returns to village using E")
	check(await walk_to(Vector2(548,421)),"Walk around village crystal to Rowan")
	await key(KEY_E)
	main.ui.finish_typing()
	main.advance_dialogue()
	check(main.quests.status=="completed","Full route completes quest and earns rewards")
	check(main.save_game(),"Full route saves valid progress")
	var hp: int = main.world.player.hp
	main.queue_free()
	await process_frame
	main = load("res://scenes/main/main.tscn").instantiate()
	main.save_path = test_path
	root.add_child(main)
	check(main.ui.continue_button.disabled==false and main.load_game(),"Fresh Main instance discovers save and continues")
	check(main.quests.status=="completed" and main.world.player.hp==hp and main.inventory.count("echo_shard")==1,"Fresh instance restores journey state entirely from disk")
	print("JOURNEY_RESULT: ",checks-failures.size(),"/",checks," checks passed")
	paused = false
	main.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
