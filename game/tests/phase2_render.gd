extends SceneTree
var main: Node
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func frames(count: int) -> void:
	for i: int in range(count):
		await process_frame

func capture(name: String) -> void:
	await frames(2)
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	var result: Error = image.save_png("res://tests/output/p2_"+name+".png")
	print("CAPTURE ",name,": ",image.get_size()," error=",result)
	if result!=OK:
		failures += 1
	for node: Node in main.ui.find_children("*","Label",true,false):
		var label := node as Label
		if label.is_visible_in_tree() and (label.get_global_rect().end.x>640.5 or label.get_global_rect().end.y>360.5):
			print("FAIL: Label outside viewport: ",label.text)
			failures += 1
	if main.mode==main.Mode.DIALOGUE and main.ui.dialogue_text.get_content_height()>main.ui.dialogue_text.size.y:
		print("FAIL: Dialogue text overflow")
		failures += 1

func run() -> void:
	main = load("res://scenes/main/main.tscn").instantiate()
	main.save_path = "user://phase2_render_only.json"
	root.add_child(main)
	await capture("menu")
	main.start_game()
	main.quests.record("npc_spoken","rowan")
	main.world.player.health.restore(68)
	main.inventory.add("herb",7)
	main.inventory.add("ore",4)
	main.travel("whispering_forest")
	await frames(24)
	await capture("forest_entry")
	var started: int = Time.get_ticks_usec()
	await frames(120)
	var seconds: float = float(Time.get_ticks_usec()-started)/1000000.0
	print("FOREST_RENDER_SAMPLE: 120 frames in ",snappedf(seconds,0.001)," s; ",snappedf(120.0/seconds,0.1)," FPS")
	main.world.player.position = Vector2(512,366)
	await frames(3)
	main.world.player.facing = "up"
	main.world.player.attack()
	await frames(6)
	await capture("combat")
	main._set_mode(main.Mode.INVENTORY_OPEN)
	main.ui.select_slot(1)
	await capture("inventory")
	main.close_overlay()
	main._set_mode(main.Mode.JOURNAL)
	await capture("journal")
	main.close_overlay()
	main.pause_game()
	main.save_game()
	await capture("save_pause")
	main.return_to_menu()
	await capture("continue")
	main.load_game()
	main.world.player.health.immunity = 0
	main.world.player.health.damage(1000,Vector2.ZERO)
	await frames(65)
	await capture("death")
	main.respawn()
	main.quests.record("object_interacted","ancient_shard")
	main.quests.record("enemy_defeated","guardian")
	main.quests.record("item_collected","echo_shard")
	main.quests.record("area_entered","dawn_village_return")
	main.world.player.position = Vector2(548,421)
	await frames(3)
	main.interact()
	main.ui.finish_typing()
	await capture("report")
	main.advance_dialogue()
	main.pause_game()
	await capture("quest_complete")
	paused = false
	main.queue_free()
	await process_frame
	print("RENDER_RESULT: ",failures," failures")
	quit(0 if failures==0 else 1)
