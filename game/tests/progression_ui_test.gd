extends SceneTree
## UI contract only. Main owns pausing, model mutation and the C/Esc actions.
var checks: int = 0
var failures: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(value: bool, description: String) -> void:
	checks += 1
	print("PASS: " if value else "FAIL: ", description)
	if not value:
		failures += 1

func frames(count: int) -> void:
	for _i: int in range(count):
		await process_frame

func fits(label: Label) -> bool:
	var font: Font = label.get_theme_font("font")
	var measured: Vector2 = font.get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size"))
	return measured.x <= label.size.x + 0.5

func run() -> void:
	var ui: Control = load("res://scenes/ui/game_ui.tscn").instantiate()
	root.add_child(ui)
	await frames(2)
	var model: RefCounted = load("res://scripts/progression/progression.gd").new()
	ui.update_progression(model)
	ui.set_resources(25.0, 50.0, 25.0, 100.0)
	ui.set_health(55, 100)
	ui.show_screen("play")
	check(ui.hp_label.text == "55 / 100" and ui.hp_bar.size.x == 72, "HP public text and 132px crop contract remain compatible")
	check(ui.energy_bar.size.x == 66 and ui.stamina_bar.size.x == 33, "Resource bars show actual independent fractions")
	check(ui.energy_label.text == "25 / 50" and ui.stamina_label.text == "25 / 100", "Energy and stamina labels use supplied current/max values")
	check(ui.xp_label.text == "XP 0 / 100" and ui.level_label.text.contains("CẤP 1"), "Fresh model shows actual level one and zero XP")
	check(ui.xp_bar.size.x == 0 and not ui.xp_bar.visible, "Zero XP does not draw a fake progress fill")
	var request: Dictionary = {"key": "", "amount": 0, "hits": 0, "open": 0, "close": 0}
	ui.character_requested.connect(func() -> void: request.open += 1)
	ui.overlay_close_requested.connect(func() -> void: request.close += 1)
	ui.allocate_stat_requested.connect(func(key: String, amount: int) -> void:
		request.key = key
		request.amount = amount
		request.hits += 1
	)
	ui.character_button.pressed.emit()
	check(request.open == 1, "Visible character button sends Main an open request")
	model.gain_experience(100)
	ui.update_progression(model)
	ui.show_screen("character")
	check(ui.character_panel.visible and not ui.hud.visible and not ui.menu.visible, "Character screen hides covered HUD and menu")
	check(ui.batch_buttons[0].has_focus(), "Opening character screen gives the keyboard a visible default")
	check(ui.stat_widgets.size() == 7 and ui.unspent_label.text == "5 điểm chưa phân bổ", "Seven real stat rows show the actual point bank")
	ui.batch_buttons[1].pressed.emit()
	var health_button: Button = ui.stat_widgets.health.button
	check(ui.allocation_batch == 5 and health_button.text == "+5" and not health_button.disabled, "Batch five applies to every available allocation row")
	health_button.pressed.emit()
	check(request.key == "health" and request.amount == 5 and request.hits == 1, "Allocate button emits the chosen stat and batch")
	check(model.unspent_points == 5 and model.allocated.health == 0, "Presentation does not mutate the progression model")
	check(model.allocate(str(request.key), int(request.amount)), "Owner can commit the requested allocation")
	ui.update_progression(model)
	check(ui.stat_widgets.health.value.text == "200 HP tối đa", "Effective stat value comes from the updated model")
	check(health_button.disabled and ui.unspent_label.text == "0 điểm chưa phân bổ", "Spent points immediately disable unaffordable allocation")
	ui.batch_buttons[3].pressed.emit()
	check(ui.allocation_batch == 100 and health_button.disabled, "Batch one hundred cannot overspend an empty bank")
	ui.character_close.pressed.emit()
	check(request.close == 1, "Character close button uses Main's existing overlay-close signal")
	var allocated: Dictionary = {}
	for stat: String in model.STAT_KEYS:
		allocated[stat] = 0
	check(model.restore({"level": 9998, "experience": model.xp_required(9998) - 1, "unspent_points": 49985, "allocated": allocated}), "Near-cap fixture is a valid real model state")
	ui.update_progression(model)
	check(fits(ui.xp_label) and fits(ui.character_summary), "Nine-digit XP requirements fit HUD and character summary")
	check(model.restore({"level": 9999, "experience": 0, "unspent_points": 49990, "allocated": allocated}), "Maximum-level fixture preserves the real point budget")
	ui.update_progression(model)
	check(ui.xp_label.text == "XP MAX" and ui.level_label.text.contains("9999") and ui.level_label.text.contains("MAX"), "Level 9999 explicitly displays MAX")
	check(model.allocate("health", 49990), "Full legal point budget can exercise maximum HP formatting")
	ui.update_progression(model)
	ui.set_health(999900, 999900)
	ui.set_resources(499950, 499950, 500000, 500000)
	check(ui.hp_label.text == "999,900 / 999,900" and fits(ui.hp_label), "Maximum legal HP remains fully readable")
	check(ui.stat_widgets.health.value.text == "999,900 HP tối đa" and fits(ui.stat_widgets.health.value), "Character stats retain full large values")
	check(fits(ui.energy_label) and fits(ui.stamina_label) and fits(ui.unspent_label), "Large vital and point-bank values fit their labels")
	for stat: String in ["health","energy","stamina","speed","luck","strength","defense"]:
		var edge: Dictionary = model.snapshot()
		for key: String in edge.allocated: edge.allocated[key] = 0
		edge.allocated[stat] = 49990
		model.restore(edge)
		ui.update_progression(model)
		check(fits(ui.stat_widgets[stat].value) and fits(ui.stat_widgets[stat].allocated), "The full legal level-9999 allocation remains readable for " + stat)
	await frames(2)
	var inside: bool = true
	for node: Node in ui.find_children("*", "Label", true, false):
		var label := node as Label
		if label.is_visible_in_tree():
			var rect: Rect2 = label.get_global_rect()
			inside = inside and rect.position.x >= -0.5 and rect.position.y >= -0.5 and rect.end.x <= 640.5 and rect.end.y <= 360.5
	check(inside, "Visible character labels remain inside the 640x360 viewport")
	var card: Panel = ui.character_panel.find_child("StatsPanel", true, false)
	var skin: StyleBoxTexture = card.get_theme_stylebox("panel")
	var initial: Texture2D = skin.texture
	var art: SpriteFrames = load("res://resources/art/ui_stats_panel.tres")
	paused = true
	await frames(ceili(60.0 / art.get_animation_speed(&"idle")) + 2)
	check(skin.texture != initial, "Character panel ambient animation continues while the world is paused")
	paused = false
	ui.show_screen("play")
	check(fits(ui.control_tips), "Footer controls including C and R remain readable")
	ui.queue_free()
	await process_frame
	print("PROGRESSION_UI_RESULT: ", checks - failures, "/", checks, " checks passed")
	quit(0 if failures == 0 else 1)
