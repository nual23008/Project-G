extends Control
## Presentation only. Main owns game state; dialogue logic lives in DialogueSession.
signal new_game_requested
signal resume_requested
signal settings_requested
signal settings_back_requested
signal menu_requested
signal quit_requested
signal dialogue_advance_requested
signal dialogue_choice_requested(index: int)
signal dialogue_close_requested
signal effects_changed(enabled: bool)
signal continue_requested
signal save_requested
signal load_requested
signal overlay_close_requested
signal item_use_requested(index: int)
signal respawn_requested

const GOLD := Color("d6bd82")
const CREAM := Color("ece5cc")
const MUTED := Color("c1b29f")
const PANEL_ART: SpriteFrames = preload("res://resources/art/ui_panel.tres")
const BUTTON_ART: SpriteFrames = preload("res://resources/art/ui_button.tres")
const HEALTH_ART: SpriteFrames = preload("res://resources/art/ui_health.tres")
const ROWAN_ART: SpriteFrames = preload("res://resources/art/rowan.tres")
const CRYSTAL_ART: SpriteFrames = preload("res://resources/art/crystal.tres")
const ITEM_ART: Dictionary = {
	"rust_sword": preload("res://resources/art/rust_sword.tres"),
	"potion": preload("res://resources/art/potion.tres"),
	"herb": preload("res://resources/art/herb.tres"),
	"ore": preload("res://resources/art/ore.tres"),
	"echo_shard": preload("res://resources/art/echo_shard.tres")
}
var menu: Control
var pause_panel: Control
var settings_panel: Control
var hud: Control
var dialogue_panel: Panel
var dialogue_text: RichTextLabel
var speaker_label: Label
var role_label: Label
var portrait: TextureRect
var next_button: Button
var close_button: Button
var choice_box: VBoxContainer
var prompt: Label
var objective: Label
var notification: Label
var notification_bg: Panel
var new_button: Button
var resume_button: Button
var back_button: Button
var fullscreen_check: CheckBox
var effects_check: CheckBox
var control_tips: Label
var letter_clock: float = 0.0
var notify_clock: float = 0.0
var typing: bool = false
var pending_choices: Array = []
var current_screen: String = "menu"
var continue_button: Button
var hp_label: Label
var hp_bar: TextureRect
var location_label: Label
var inventory_panel: Control
var journal_panel: Control
var death_panel: Control
var inventory_buttons: Array[Button] = []
var inventory_detail: Label
var use_button: Button
var journal_text: RichTextLabel
var save_status: Label
var selected_slot: int = 0
var inventory_model: RefCounted
var art_clock: float = 0.0
var material_styles: Array[Dictionary] = []
var health_crop := AtlasTexture.new()
var portrait_art: SpriteFrames
var portrait_state: StringName = &"idle"

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_create_theme()
	_build_menu()
	_build_hud()
	_build_pause()
	_build_settings()
	_build_dialogue()
	_build_rpg_panels()
	show_screen("menu")

func _create_theme() -> void:
	theme = Theme.new()
	theme.default_font = preload("res://assets/fonts/NotoSans-Regular.ttf")
	theme.default_font_size = 12
	var normal := _art_style(BUTTON_ART, &"normal")
	var hover := _art_style(BUTTON_ART, &"hover")
	var pressed := _art_style(BUTTON_ART, &"pressed")
	theme.set_stylebox("normal", "Button", normal)
	theme.set_stylebox("hover", "Button", hover)
	theme.set_stylebox("pressed", "Button", pressed)
	theme.set_stylebox("hover_pressed", "Button", pressed)
	var focus := _art_style(BUTTON_ART, &"focus")
	focus.draw_center = false
	theme.set_stylebox("focus", "Button", focus)
	var disabled := _art_style(BUTTON_ART, &"normal")
	disabled.modulate_color = Color(0.67, 0.61, 0.64, 1.0)
	theme.set_stylebox("disabled", "Button", disabled)
	theme.set_color("font_color", "Button", CREAM)
	theme.set_color("font_hover_color", "Button", GOLD)
	theme.set_color("font_focus_color", "Button", CREAM)
	theme.set_color("font_disabled_color", "Button", Color("b5a899"))
	theme.set_constant("icon_max_width", "Button", 24)
	theme.set_stylebox("panel", "Panel", _art_style(PANEL_ART, &"idle"))
	theme.set_color("font_color", "Label", CREAM)
	theme.set_color("font_color", "CheckBox", CREAM)

func _art_style(frames: SpriteFrames, state: StringName) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = frames.get_frame_texture(state, 0)
	style.texture_margin_left = 4
	style.texture_margin_right = 4
	style.texture_margin_top = 4
	style.texture_margin_bottom = 4
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	material_styles.append({"style": style, "frames": frames, "state": state, "frame": 0})
	return style

func _art_frame(frames: SpriteFrames, state: StringName) -> Texture2D:
	var count: int = frames.get_frame_count(state)
	var index: int = int(art_clock * frames.get_animation_speed(state))
	index = posmod(index, count) if frames.get_animation_loop(state) else mini(index, count - 1)
	return frames.get_frame_texture(state, index)

func _animate_art(delta: float) -> void:
	art_clock += delta
	for entry: Dictionary in material_styles:
		var frames: SpriteFrames = entry.frames
		var index: int = posmod(int(art_clock * frames.get_animation_speed(entry.state)), frames.get_frame_count(entry.state))
		if index != int(entry.frame):
			entry.frame = index
			var style: StyleBoxTexture = entry.style
			style.texture = frames.get_frame_texture(entry.state, index)
	health_crop.atlas = _art_frame(HEALTH_ART, &"idle")
	if dialogue_panel.visible and portrait_art != null:
		portrait.texture = _art_frame(portrait_art, portrait_state)
	if inventory_panel.visible and inventory_model != null:
		for i: int in range(inventory_buttons.size()):
			var slot: Dictionary = inventory_model.slots[i]
			if not slot.is_empty():
				var frames: SpriteFrames = ITEM_ART[str(slot.id)]
				inventory_buttons[i].icon = _art_frame(frames, &"idle")

func _root() -> Control:
	var node := Control.new()
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(node)
	return node

func _panel(parent: Node, rect: Rect2) -> Panel:
	var node := Panel.new()
	node.position = rect.position
	node.size = rect.size
	parent.add_child(node)
	return node

func _label(parent: Node, text: String, rect: Rect2, font_size: int = 12, color: Color = CREAM) -> Label:
	var node := Label.new()
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	node.clip_text = true
	parent.add_child(node)
	# Assign layout after inheriting the real font. The engine default font would
	# otherwise grow the minimum width before the smaller HUD font is applied.
	node.text = text
	node.position = rect.position
	node.size = rect.size
	return node

func _button(parent: Node, text: String, rect: Rect2, callback: Callable) -> Button:
	var node := Button.new()
	node.text = text
	node.position = rect.position
	node.size = rect.size
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.pressed.connect(callback)
	parent.add_child(node)
	return node

func _shade(parent: Node, alpha: float) -> void:
	var node := ColorRect.new()
	node.color = Color(0.015, 0.045, 0.07, alpha)
	node.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(node)

func _build_menu() -> void:
	menu = _root()
	_shade(menu, 0.28)
	_panel(menu, Rect2(0, 0, 330, 360))
	_label(menu, "E C H O E S   O F   A E T H E R I A", Rect2(36, 25, 300, 18), 9, GOLD)
	_label(menu, "DƯ ÂM\nTHẾ GIỚI\nLÃNG QUÊN", Rect2(33, 54, 290, 117), 29)
	_label(menu, "Có những điều thế giới chưa kịp quên.", Rect2(36, 183, 285, 20), 10, MUTED)
	new_button = _button(menu, "Hành trình mới     →", Rect2(36, 211, 248, 29), new_game_requested.emit)
	continue_button = _button(menu, "Tiếp tục bản lưu", Rect2(36, 246, 248, 29), continue_requested.emit)
	_button(menu, "Cài đặt", Rect2(36, 281, 120, 27), settings_requested.emit)
	_button(menu, "Thoát", Rect2(164, 281, 120, 27), quit_requested.emit)
	_label(menu, "HÀNH TRÌNH KHỞI ĐẦU", Rect2(36, 315, 280, 17), 9, GOLD)
	_label(menu, "Làng Bình Minh • Rừng Thì Thầm", Rect2(36, 333, 290, 16), 9, MUTED)
	var caption := _label(menu, "LÀNG BÌNH MINH\nMột buổi sớm sau Đêm Lặng", Rect2(365, 302, 245, 43), 11)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

func _build_hud() -> void:
	hud = _root()
	var health := _panel(hud, Rect2(12, 12, 153, 43))
	health.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label(health, "LỮ KHÁCH", Rect2(10, 4, 85, 18), 10, GOLD)
	hp_label = _label(health, "100 / 100", Rect2(94, 4, 54, 18), 9, CREAM)
	var bar := TextureRect.new()
	bar.position = Vector2(10, 29)
	bar.size = Vector2(132, 5)
	bar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bar.stretch_mode = TextureRect.STRETCH_KEEP
	health_crop.atlas = HEALTH_ART.get_frame_texture(&"idle", 0)
	health_crop.region = Rect2(0, 0, 132, 5)
	health_crop.filter_clip = true
	bar.texture = health_crop
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	health.add_child(bar)
	hp_bar = bar
	var location_bg := _panel(hud, Rect2(402, 12, 226, 39))
	location_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var location := _label(location_bg, "LÀNG BÌNH MINH\nBình yên trong những khoảng quên", Rect2(6, 2, 214, 35), 10, CREAM)
	location.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	location_label = location
	var objective_bg := _panel(hud, Rect2(12, 64, 269, 44))
	objective_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	objective = _label(objective_bg, "BƯỚC CHÂN ĐẦU TIÊN\nTìm Rowan bên đài tinh thể, phía bắc.", Rect2(9, 3, 254, 37), 10, GOLD)
	objective.add_theme_color_override("font_shadow_color", Color("102731"))
	objective.add_theme_constant_override("shadow_offset_x", 1)
	objective.add_theme_constant_override("shadow_offset_y", 1)
	prompt = _label(hud, "", Rect2(155, 287, 330, 28), 12, GOLD)
	prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt.add_theme_color_override("font_shadow_color", Color("102731"))
	prompt.add_theme_constant_override("shadow_offset_y", 1)
	var footer_bg := _panel(hud, Rect2(0, 334, 640, 26))
	footer_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	control_tips = _label(hud, "WASD  Đi lại     SHIFT  Chạy     E  Tương tác     ESC  Tạm dừng", Rect2(0, 338, 640, 19), 9, CREAM)
	control_tips.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	control_tips.add_theme_color_override("font_shadow_color", Color("102731"))
	control_tips.add_theme_constant_override("shadow_offset_y", 1)
	notification_bg = _panel(hud, Rect2(91, 304, 458, 27))
	notification_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notification_bg.hide()
	notification = _label(hud, "", Rect2(95, 306, 450, 23), 10, CREAM)
	notification.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

func _build_pause() -> void:
	pause_panel = _root()
	_shade(pause_panel, 0.68)
	var panel := _panel(pause_panel, Rect2(203, 28, 234, 302))
	_label(panel, "NGỌN LỬA TẠM NGHỈ", Rect2(18, 16, 208, 24), 13, GOLD)
	_label(panel, "Hành trình vẫn chờ bạn.", Rect2(18, 43, 200, 20), 10, MUTED)
	resume_button = _button(panel, "Tiếp tục", Rect2(18, 70, 198, 27), resume_requested.emit)
	_button(panel, "Lưu hành trình  [F5]", Rect2(18, 103, 198, 27), save_requested.emit)
	_button(panel, "Tải bản lưu", Rect2(18, 136, 198, 27), load_requested.emit)
	_button(panel, "Cài đặt", Rect2(18, 169, 198, 27), settings_requested.emit)
	_button(panel, "Về màn hình chính", Rect2(18, 202, 198, 27), menu_requested.emit)
	save_status = _label(panel, "Một ô lưu. Lưu sẽ thay bản hiện tại.\nVề menu không tự lưu.", Rect2(18, 239, 201, 48), 9, MUTED)
	save_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

func _build_settings() -> void:
	settings_panel = _root()
	_shade(settings_panel, 0.72)
	var panel := _panel(settings_panel, Rect2(170, 58, 300, 246))
	_label(panel, "CÀI ĐẶT HÌNH ẢNH", Rect2(18, 13, 260, 25), 14, GOLD)
	_label(panel, "640 × 360 · pixel nguyên · giữ trong phiên", Rect2(18, 43, 268, 20), 10, MUTED)
	fullscreen_check = CheckBox.new()
	fullscreen_check.text = "Toàn màn hình  [F11]"
	fullscreen_check.position = Vector2(18, 77)
	fullscreen_check.size = Vector2(264, 30)
	fullscreen_check.toggled.connect(_set_fullscreen)
	panel.add_child(fullscreen_check)
	effects_check = CheckBox.new()
	effects_check.text = "Ánh sáng & đom đóm"
	effects_check.position = Vector2(18, 115)
	effects_check.size = Vector2(264, 30)
	effects_check.button_pressed = true
	effects_check.toggled.connect(effects_changed.emit)
	panel.add_child(effects_check)
	_label(panel, "Kéo mép cửa sổ để đổi kích thước.\nTỷ lệ nguyên giữ hình ảnh sắc nét.", Rect2(18, 153, 264, 38), 10, MUTED)
	back_button = _button(panel, "Quay lại", Rect2(18, 202, 264, 28), settings_back_requested.emit)

func _set_fullscreen(enabled: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED)

func sync_fullscreen() -> void:
	fullscreen_check.set_pressed_no_signal(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)

func _build_dialogue() -> void:
	dialogue_panel = _panel(self, Rect2(24, 205, 592, 137))
	speaker_label = _label(dialogue_panel, "", Rect2(16, 9, 480, 19), 12, GOLD)
	role_label = _label(dialogue_panel, "", Rect2(16, 28, 480, 16), 9, MUTED)
	portrait = TextureRect.new()
	portrait.position = Vector2(18, 50)
	portrait.size = Vector2(48, 64)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_panel.add_child(portrait)
	dialogue_text = RichTextLabel.new()
	dialogue_text.position = Vector2(88, 47)
	dialogue_text.size = Vector2(486, 64)
	dialogue_text.add_theme_font_size_override("normal_font_size", 12)
	dialogue_text.add_theme_color_override("default_color", CREAM)
	dialogue_text.scroll_active = false
	dialogue_text.bbcode_enabled = false
	dialogue_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_panel.add_child(dialogue_text)
	next_button = _button(dialogue_panel, "Tiếp tục  [E]", Rect2(440, 109, 134, 23), dialogue_advance_requested.emit)
	next_button.add_theme_font_size_override("font_size", 10)
	close_button = _button(dialogue_panel, "×", Rect2(557, 9, 22, 22), dialogue_close_requested.emit)
	close_button.focus_mode = Control.FOCUS_NONE
	choice_box = VBoxContainer.new()
	choice_box.position = Vector2(88, 110)
	choice_box.size = Vector2(486, 80)
	choice_box.add_theme_constant_override("separation", 3)
	dialogue_panel.add_child(choice_box)

func show_screen(screen: String) -> void:
	current_screen = screen
	menu.visible = screen == "menu"
	pause_panel.visible = screen == "pause"
	settings_panel.visible = screen == "settings"
	hud.visible = screen in ["play", "dialogue"]
	dialogue_panel.visible = screen == "dialogue"
	inventory_panel.visible = screen == "inventory"
	journal_panel.visible = screen == "journal"
	death_panel.visible = screen == "death"
	prompt.visible = screen == "play"
	notification.visible = screen == "play"
	control_tips.text = "E / ENTER  Hiện chữ / tiếp     TAB / ENTER  Chọn     ESC  Đóng" if screen == "dialogue" else "WASD Đi  SHIFT Chạy  J/Chuột Đánh  E Tương tác  H Thuốc  I Túi  Q Nhật ký  F5 Lưu"
	if screen != "dialogue":
		typing = false
	match screen:
		"menu": new_button.grab_focus()
		"pause": resume_button.grab_focus()
		"settings":
			sync_fullscreen()
			fullscreen_check.grab_focus()
		"play":
			var focused: Control = get_viewport().gui_get_focus_owner()
			if focused != null:
				focused.release_focus()
		"inventory": inventory_buttons[selected_slot].grab_focus()
		"journal": (journal_panel.find_child("JournalClose",true,false) as Button).grab_focus()
		"death": (death_panel.find_child("Respawn",true,false) as Button).grab_focus()

func show_line(speaker: String, role: String, text: String, choices: Array, face: String) -> void:
	show_screen("dialogue")
	speaker_label.text = speaker
	role_label.text = role
	dialogue_text.text = text
	dialogue_text.visible_characters = 0
	letter_clock = 0.0
	typing = true
	pending_choices = choices
	next_button.hide()
	for child: Node in choice_box.get_children():
		choice_box.remove_child(child)
		child.queue_free()
	var expanded: bool = text.count("\n") >= 2
	dialogue_panel.position.y = 143 if not choices.is_empty() else (151 if expanded else 205)
	dialogue_panel.size.y = 199 if not choices.is_empty() else (191 if expanded else 137)
	dialogue_text.size.y = 112 if expanded and choices.is_empty() else 64
	next_button.position.y = 163 if expanded else 109
	if face == "rowan":
		portrait_art = ROWAN_ART
		portrait_state = &"idle_down"
	else:
		portrait_art = CRYSTAL_ART
		portrait_state = &"idle"
	portrait.texture = _art_frame(portrait_art, portrait_state)
	for i: int in range(choices.size()):
		var option := Button.new()
		option.text = str(i+1) + "   " + str(choices[i].text)
		option.alignment = HORIZONTAL_ALIGNMENT_LEFT
		option.custom_minimum_size = Vector2(486, 24)
		option.add_theme_font_size_override("font_size", 11)
		option.pressed.connect(func() -> void: dialogue_choice_requested.emit(i))
		choice_box.add_child(option)
	choice_box.hide()
	# Enter during typing must skip text, never accidentally activate Close.
	var focused: Control = get_viewport().gui_get_focus_owner()
	if focused != null:
		focused.release_focus()

func finish_typing() -> void:
	dialogue_text.visible_characters = -1
	typing = false
	_reveal_actions()

func _reveal_actions() -> void:
	if pending_choices.is_empty():
		next_button.show()
		next_button.grab_focus()
	else:
		choice_box.show()
		if choice_box.get_child_count() > 0:
			(choice_box.get_child(0) as Button).grab_focus()

func set_prompt(target: Node2D) -> void:
	prompt.text = "[E]  " + str(target.get("display_name")) if is_instance_valid(target) else ""

func set_met_rowan(met: bool) -> void:
	objective.text = "BÌNH MINH CÒN Ở ĐÂY\nĐã gặp Rowan · Khám phá làng và bờ hồ." if met else "BƯỚC CHÂN ĐẦU TIÊN\nTìm Rowan bên đài tinh thể, phía bắc."

func notify(text: String) -> void:
	notification.text = text
	notify_clock = 6.0

func _process(delta: float) -> void:
	_animate_art(delta)
	notification_bg.visible = current_screen == "play" and notify_clock > 0.0 and not notification.text.is_empty()
	if typing:
		letter_clock += delta * 38.0
		dialogue_text.visible_characters = int(letter_clock)
		if dialogue_text.visible_characters >= dialogue_text.get_total_character_count():
			finish_typing()
	if notify_clock > 0.0:
		notify_clock -= delta
		notification.modulate.a = minf(1.0, notify_clock)

func _build_rpg_panels() -> void:
	inventory_panel = _root()
	_shade(inventory_panel,0.7)
	var panel := _panel(inventory_panel,Rect2(54,35,532,292))
	_label(panel,"TÚI HÀNH TRANG  [I]",Rect2(18,12,450,24),16,GOLD)
	_label(panel,"16 ô • Chọn bằng chuột hoặc Tab / Enter",Rect2(18,43,490,20),10,MUTED)
	for i: int in range(16):
		var button := _button(panel,"",Rect2(18+(i%4)*51,76+(i/4)*42,46,37),func() -> void: select_slot(i))
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.expand_icon = true
		button.add_theme_font_size_override("font_size",9)
		inventory_buttons.append(button)
	inventory_detail = _label(panel,"",Rect2(237,76,274,126),12,CREAM)
	inventory_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	use_button = _button(panel,"Dùng vật phẩm",Rect2(237,212,274,27),func() -> void: item_use_requested.emit(selected_slot))
	_button(panel,"Đóng",Rect2(18,251,493,27),overlay_close_requested.emit)
	journal_panel = _root()
	_shade(journal_panel,0.7)
	panel = _panel(journal_panel,Rect2(52,28,536,304))
	_label(panel,"NHẬT KÝ  [Q]",Rect2(18,10,480,25),16,GOLD)
	journal_text = RichTextLabel.new()
	journal_text.position = Vector2(18,47)
	journal_text.size = Vector2(500,207)
	journal_text.add_theme_font_size_override("normal_font_size",12)
	journal_text.add_theme_color_override("default_color",CREAM)
	panel.add_child(journal_text)
	var close := _button(panel,"Đóng nhật ký",Rect2(18,263,500,27),overlay_close_requested.emit)
	close.name = "JournalClose"
	death_panel = _root()
	_shade(death_panel,0.8)
	panel = _panel(death_panel,Rect2(153,88,334,187))
	_label(panel,"ÁNH SÁNG CHƯA TẮT",Rect2(20,16,294,28),18,GOLD)
	_label(panel,"Bạn gục ngã. Hồi sinh ở làng, giữ đồ và\ntiến trình đã có. Bản lưu không bị thay đổi.",Rect2(20,56,294,45),11,CREAM)
	var respawn := _button(panel,"Trở về làng Bình Minh",Rect2(20,114,294,30),respawn_requested.emit)
	respawn.name = "Respawn"
	_button(panel,"Về màn hình chính",Rect2(20,151,294,25),menu_requested.emit)

func set_save_available(available: bool) -> void:
	continue_button.disabled = not available
	continue_button.tooltip_text = "Tải bản lưu đã kiểm tra hợp lệ" if available else "Chưa có bản lưu hợp lệ"

func set_health(current: int, maximum: int) -> void:
	hp_label.text = str(current)+" / "+str(maximum)
	var width: float = floorf(132.0 * clampf(float(current) / maxf(1.0, float(maximum)), 0.0, 1.0))
	hp_bar.size.x = width
	hp_bar.visible = width > 0
	health_crop.region = Rect2(0, 0, maxf(1.0, width), 5)
	hp_bar.modulate = Color.WHITE if current > maximum / 3 else Color("e6a28e")

func update_inventory(model: RefCounted) -> void:
	inventory_model = model
	for i: int in range(16):
		var slot: Dictionary = model.slots[i]
		var button: Button = inventory_buttons[i]
		button.icon = null
		button.text = "·"
		button.tooltip_text = "Ô trống"
		if not slot.is_empty():
			var item: Dictionary = model.database[slot.id]
			var frames: SpriteFrames = ITEM_ART[str(slot.id)]
			button.icon = _art_frame(frames, &"idle")
			button.text = str(slot.count)
			button.tooltip_text = str(item.name)+"\n"+str(item.description)
	select_slot(selected_slot)

func select_slot(index: int) -> void:
	selected_slot = index
	if inventory_model == null:
		return
	var slot: Dictionary = inventory_model.slots[index]
	use_button.disabled = true
	inventory_detail.text = "Ô trống" if slot.is_empty() else str(inventory_model.database[slot.id].name)+" ×"+str(slot.count)+"\n\n"+str(inventory_model.database[slot.id].description)
	if not slot.is_empty():
		use_button.disabled = inventory_model.database[slot.id].type != "consumable"

func update_quest(model: RefCounted) -> void:
	objective.text = "DƯ ÂM ĐẦU TIÊN\n"+model.objective_text()
	journal_text.text = str(model.definition.name)+" — "+{"available":"Chưa nhận","active":"Đang làm","completed":"Hoàn thành chặng rừng"}[model.status]+"\n\n"
	for i: int in range(model.definition.objectives.size()):
		journal_text.text += ("[✓] " if model.done(i) else "[  ] ")+str(model.definition.objectives[i].text)+"\n"
	journal_text.text += "\nThưởng: 2 thuốc hồi phục, 3 quặng ký ức.\n"+str(model.definition.description)
