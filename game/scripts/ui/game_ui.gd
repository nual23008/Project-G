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
signal allocate_stat_requested(stat: String, amount: int)
signal character_requested
signal hub_requested
signal hub_tab_requested(index: int)
signal zoom_requested(step: int)
signal equip_requested(index: int, slot: String)
signal unequip_requested(slot: String)

const GOLD := Color("d6bd82")
const CREAM := Color("ece5cc")
const MUTED := Color("c1b29f")
const PANEL_ART: SpriteFrames = preload("res://resources/art/ui_panel.tres")
const BUTTON_ART: SpriteFrames = preload("res://resources/art/ui_button.tres")
const HEALTH_ART: SpriteFrames = preload("res://resources/art/ui_health.tres")
const EXPERIENCE_ART: SpriteFrames = preload("res://resources/art/ui_experience.tres")
const ENERGY_ART: SpriteFrames = preload("res://resources/art/ui_energy.tres")
const STAMINA_ART: SpriteFrames = preload("res://resources/art/ui_stamina.tres")
const STATS_PANEL_ART: SpriteFrames = preload("res://resources/art/ui_stats_panel.tres")
const STAT_ROWS: Array[Dictionary] = [
	{"key": "health", "name": "Máu", "description": "+20 máu tối đa mỗi điểm."},
	{"key": "energy", "name": "Năng lượng", "description": "+10/điểm. Chuột phải: 20 NL, đòn ×1.8."},
	{"key": "stamina", "name": "Thể lực", "description": "+10 tối đa/điểm. Chạy 18/s; hồi 20/s."},
	{"key": "speed", "name": "Tốc độ", "description": "Đi / chạy; tăng giảm dần đến 180 / 280."},
	{"key": "luck", "name": "May mắn", "description": "Tăng chí mạng và XP, mỗi tỷ lệ dưới 50%."},
	{"key": "strength", "name": "Sức mạnh", "description": "+1 sức mạnh, +2 sát thương mỗi điểm."},
	{"key": "defense", "name": "Phòng thủ", "description": "Giảm sát thương dưới 80%; luôn nhận ≥1."}
]
const ROWAN_ART: SpriteFrames = preload("res://resources/art/rowan.tres")
const CRYSTAL_ART: SpriteFrames = preload("res://resources/art/crystal.tres")
var ITEM_ART: Dictionary = {
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
var level_label: Label
var xp_label: Label
var xp_bar: TextureRect
var energy_label: Label
var energy_bar: TextureRect
var stamina_label: Label
var stamina_bar: TextureRect
var character_button: Button
var character_panel: Control
var character_title: Label
var character_summary: Label
var unspent_label: Label
var allocated_summary: Label
var character_close: Button
var allocation_batch: int = 1
var batch_buttons: Array[Button] = []
var stat_widgets: Dictionary = {}
var progression_model: RefCounted
var progression_bars: Array[Dictionary] = []
var hub_navigation: Control
var hub_tabs: Array[Button] = []
var zoom_label: Label
var equipment_buttons: Dictionary = {}
var selected_equipment: String = "weapon_right"
var unequip_button: Button
var equipment_preview: Node2D
var equipment_damage: Label

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_create_theme()
	var catalog: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://resources/items/items.json"))
	for id: String in catalog:
		_item_art(id)
	_build_menu()
	_build_hud()
	_build_pause()
	_build_settings()
	_build_dialogue()
	_build_rpg_panels()
	_build_character_panel()
	_build_hub_navigation()
	resized.connect(_layout_expanded)
	_layout_expanded()
	show_screen("menu")

func _build_hub_navigation() -> void:
	hub_navigation = _root()
	for i: int in range(4):
		var button := _button(hub_navigation,["Túi đồ","Nâng điểm","Nhiệm vụ","Hệ thống"][i],Rect2(18+i*151,4,145,27),func() -> void: hub_tab_requested.emit(i))
		button.toggle_mode = true
		hub_tabs.append(button)

func _layout_expanded() -> void:
	var extra: Vector2 = (size-Vector2(640,360)).max(Vector2.ZERO)
	for overlay: Control in [menu,pause_panel,settings_panel,inventory_panel,journal_panel,character_panel,death_panel,hub_navigation]:
		if not is_instance_valid(overlay): continue
		overlay.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
		overlay.position = extra/2.0
		overlay.size = Vector2(640,360)
		for child: Node in overlay.get_children():
			if child.has_meta(&"screen_shade"):
				child.set_anchors_and_offsets_preset(Control.PRESET_TOP_LEFT)
				child.position = -extra/2.0
				child.size = size

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
	if frames == STATS_PANEL_ART:
		style.texture_margin_left = 6
		style.texture_margin_right = 6
		style.texture_margin_top = 6
		style.texture_margin_bottom = 6
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	material_styles.append({"style": style, "frames": frames, "state": state, "frame": 0})
	return style

func _item_art(id: String) -> SpriteFrames:
	# Resolve at use as well as startup: a catalog item never assumes an old
	# five-item UI cache already knows its icon (including steel_sword).
	if not ITEM_ART.has(id):
		var resource_path: String = "res://resources/art/"+id+".tres"
		ITEM_ART[id] = load(resource_path) if ResourceLoader.exists(resource_path) else null
		if ITEM_ART[id] == null: push_error("Missing item animation resource: "+resource_path)
	return ITEM_ART[id] as SpriteFrames

func _art_frame(frames: SpriteFrames, state: StringName) -> Texture2D:
	if frames == null: return null
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
	for entry: Dictionary in progression_bars:
		var crop: AtlasTexture = entry.crop
		crop.atlas = _art_frame(entry.frames, &"idle")
		var track: TextureRect = entry.track
		track.texture = crop.atlas
	if dialogue_panel.visible and portrait_art != null:
		portrait.texture = _art_frame(portrait_art, portrait_state)
	if inventory_panel.visible and inventory_model != null:
		for slot: String in equipment_buttons:
			var id: String = str(inventory_model.equipment[slot])
			if not id.is_empty(): equipment_buttons[slot].icon = _art_frame(_item_art(id),&"idle")
		for i: int in range(inventory_buttons.size()):
			var slot: Dictionary = inventory_model.slots[i]
			if not slot.is_empty():
				var frames: SpriteFrames = _item_art(str(slot.id))
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
	node.set_meta(&"screen_shade",true)
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
	var health := _panel(hud, Rect2(12, 12, 190, 82))
	health.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_label = _label(health, "LỮ KHÁCH · CẤP —", Rect2(8, 2, 174, 17), 9, GOLD)
	_label(health, "Máu", Rect2(8, 18, 56, 14), 8, MUTED)
	hp_label = _label(health, "100 / 100", Rect2(68, 18, 114, 14), 8, CREAM)
	hp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var bar := TextureRect.new()
	bar.position = Vector2(8, 32)
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
	_label(health, "Năng lượng", Rect2(8, 37, 56, 14), 8, MUTED)
	energy_label = _label(health, "—", Rect2(68, 37, 114, 14), 8, CREAM)
	energy_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	energy_bar = _progression_bar(health, Vector2(8, 51), ENERGY_ART)
	_label(health, "Thể lực", Rect2(8, 56, 56, 14), 8, MUTED)
	stamina_label = _label(health, "—", Rect2(68, 56, 114, 14), 8, CREAM)
	stamina_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stamina_bar = _progression_bar(health, Vector2(8, 70), STAMINA_ART)
	var experience := _panel(hud, Rect2(212, 12, 182, 39))
	experience.mouse_filter = Control.MOUSE_FILTER_IGNORE
	xp_label = _label(experience, "XP —", Rect2(8, 3, 166, 18), 8, GOLD)
	xp_bar = _progression_bar(experience, Vector2(8, 26), EXPERIENCE_ART)
	character_button = _button(hud, "Hành trang  [E]", Rect2(285, 58, 109, 25), hub_requested.emit)
	character_button.add_theme_font_size_override("font_size", 10)
	character_button.tooltip_text = "Túi đồ · Nâng điểm · Nhiệm vụ · Lưu / tải / cài đặt"
	var location_bg := _panel(hud, Rect2(402, 12, 226, 39))
	location_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var location := _label(location_bg, "LÀNG BÌNH MINH\nBình yên trong những khoảng quên", Rect2(6, 2, 214, 35), 10, CREAM)
	location.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	location_label = location
	location_bg.anchor_left = 1.0
	location_bg.anchor_right = 1.0
	location_bg.offset_left = -238
	location_bg.offset_right = -12
	var objective_bg := _panel(hud, Rect2(12, 98, 269, 43))
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
	footer_bg.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	footer_bg.offset_top = -26
	control_tips = _label(hud, "WASD  Đi lại     SHIFT  Chạy     E  Tương tác     ESC  Tạm dừng", Rect2(0, 338, 640, 19), 9, CREAM)
	control_tips.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	control_tips.add_theme_color_override("font_shadow_color", Color("102731"))
	control_tips.add_theme_constant_override("shadow_offset_y", 1)
	control_tips.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	control_tips.offset_top = -22
	control_tips.offset_bottom = -3
	prompt.anchor_left = 0.5
	prompt.anchor_right = 0.5
	prompt.anchor_top = 1.0
	prompt.anchor_bottom = 1.0
	prompt.offset_left = -165
	prompt.offset_right = 165
	prompt.offset_top = -73
	prompt.offset_bottom = -45
	notification_bg = _panel(hud, Rect2(91, 304, 458, 27))
	notification_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	notification_bg.hide()
	notification = _label(hud, "", Rect2(95, 306, 450, 23), 10, CREAM)
	notification.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for node: Control in [notification,notification_bg]:
		node.anchor_left = 0.5
		node.anchor_right = 0.5
		node.anchor_top = 1.0
		node.anchor_bottom = 1.0
		node.offset_left = -229 if node == notification_bg else -225
		node.offset_right = 229 if node == notification_bg else 225
		node.offset_top = -56 if node == notification_bg else -54
		node.offset_bottom = -29 if node == notification_bg else -31

func _build_pause() -> void:
	pause_panel = _root()
	_shade(pause_panel, 0.68)
	var panel := _panel(pause_panel, Rect2(203, 28, 234, 302))
	_label(panel, "NGỌN LỬA TẠM NGHỈ", Rect2(18, 16, 208, 24), 13, GOLD)
	_label(panel, "Hành trình vẫn chờ bạn.", Rect2(18, 43, 200, 20), 10, MUTED)
	resume_button = _button(panel, "Tiếp tục", Rect2(18, 70, 198, 27), resume_requested.emit)
	_button(panel, "Lưu hành trình", Rect2(18, 103, 198, 27), save_requested.emit)
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
	_label(panel, "Phủ màn hình · pixel nearest · zoom cảnh", Rect2(18, 43, 268, 20), 10, MUTED)
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
	zoom_label = _label(panel,"Zoom 100%",Rect2(18,153,100,23),10,CREAM)
	_button(panel,"−",Rect2(125,150,38,26),func() -> void: zoom_requested.emit(-1))
	_button(panel,"+",Rect2(168,150,38,26),func() -> void: zoom_requested.emit(1))
	_button(panel,"100%",Rect2(211,150,68,26),func() -> void: zoom_requested.emit(0))
	_label(panel,"Con lăn chuột phóng to / thu nhỏ khi chơi.",Rect2(18,180,264,19),9,MUTED)
	back_button = _button(panel, "Quay lại", Rect2(18, 202, 264, 28), settings_back_requested.emit)

func _set_fullscreen(enabled: bool) -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED)

func sync_fullscreen() -> void:
	fullscreen_check.set_pressed_no_signal(DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)

func set_zoom(value: float) -> void:
	zoom_label.text = "Zoom %d%%" % roundi(value*100)

func _build_dialogue() -> void:
	dialogue_panel = _panel(self, Rect2(24, 205, 592, 137))
	dialogue_panel.anchor_left = 0.5
	dialogue_panel.anchor_right = 0.5
	dialogue_panel.anchor_top = 1.0
	dialogue_panel.anchor_bottom = 1.0
	dialogue_panel.offset_left = -296
	dialogue_panel.offset_right = 296
	dialogue_panel.offset_top = -155
	dialogue_panel.offset_bottom = -18
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
	pause_panel.visible = screen in ["pause","system"]
	settings_panel.visible = screen == "settings"
	hud.visible = screen in ["play", "dialogue"]
	dialogue_panel.visible = screen == "dialogue"
	inventory_panel.visible = screen == "inventory"
	journal_panel.visible = screen == "journal"
	death_panel.visible = screen == "death"
	character_panel.visible = screen == "character"
	hub_navigation.visible = screen in ["inventory","character","journal","system"]
	for i: int in range(hub_tabs.size()):
		hub_tabs[i].set_pressed_no_signal(["inventory","character","journal","system"][i] == screen)
	character_button.disabled = screen != "play"
	prompt.visible = screen == "play"
	notification.visible = screen == "play"
	control_tips.text = "E / ENTER  Tiếp tục · TAB / ENTER  Chọn · ESC  Đóng" if screen == "dialogue" else "WASD Đi · Shift Chạy · Chuột trái Chém · Chuột phải Tương tác / Cường hóa · E Túi · Lăn Zoom"
	if screen != "dialogue":
		typing = false
	match screen:
		"menu": new_button.grab_focus()
		"pause", "system": resume_button.grab_focus()
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
		"character":
			if progression_model != null:
				update_progression(progression_model)
			batch_buttons[0].grab_focus()

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
	dialogue_panel.offset_top = -217 if not choices.is_empty() else (-209 if expanded else -155)
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
	prompt.text = "[Chuột phải / F]  " + str(target.get("display_name")) if is_instance_valid(target) else ""

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
	var panel := _panel(inventory_panel,Rect2(10,35,620,313))
	_label(panel,"HÀNH TRANG & TRANG BỊ",Rect2(14,7,420,23),14,GOLD)
	_button(panel,"Đóng",Rect2(540,7,66,24),overlay_close_requested.emit)
	var inv := preload("res://scripts/inventory/inventory.gd")
	var equipment_order: Array[String] = ["hat","necklace","shirt","pants","shoe_left","shoe_right","bracelet_left","bracelet_right","glove_left","glove_right","weapon_left","weapon_right"]
	for i: int in range(inv.EQUIPMENT_SLOTS.size()):
		var slot: String = equipment_order[i]
		var button := _button(panel,inv.SLOT_NAMES[inv.EQUIPMENT_SLOTS.find(slot)],Rect2(12+(i%2)*96,42+(i/2)*36,92,31),func() -> void: select_equipment(slot))
		button.add_theme_font_size_override("font_size",8)
		button.add_theme_constant_override("icon_max_width",16)
		button.size = Vector2(92,31)
		button.toggle_mode = true
		equipment_buttons[slot] = button
	var preview_base := AnimatedSprite2D.new()
	preview_base.sprite_frames = preload("res://resources/art/player.tres")
	preview_base.centered = false
	preview_base.offset = Vector2(-48,-60)
	preview_base.position = Vector2(302,190)
	preview_base.scale = Vector2(2,2)
	panel.add_child(preview_base)
	preview_base.play(&"idle_down")
	equipment_preview = preload("res://scripts/player/equipment_visual.gd").new()
	equipment_preview.position = preview_base.position
	equipment_preview.scale = preview_base.scale
	panel.add_child(equipment_preview)
	equipment_preview.setup(preview_base)
	equipment_damage = _label(panel,"",Rect2(210,193,190,20),10,GOLD)
	_label(panel,"TÚI ĐỒ · 16 Ô",Rect2(426,32,180,18),10,GOLD)
	for i: int in range(16):
		var button := _button(panel,"",Rect2(426+(i%4)*44,55+(i/4)*38,40,34),func() -> void: select_slot(i))
		button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		button.expand_icon = true
		button.add_theme_font_size_override("font_size",9)
		inventory_buttons.append(button)
	inventory_detail = _label(panel,"",Rect2(210,218,394,45),10,CREAM)
	inventory_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	use_button = _button(panel,"Dùng / Trang bị",Rect2(210,271,190,26),_activate_inventory_item)
	unequip_button = _button(panel,"Tháo ô đã chọn",Rect2(410,271,194,26),func() -> void: unequip_requested.emit(selected_equipment))
	use_button.tooltip_text = "Đổi đồ ngắt đòn đang vung; giữ hồi chiêu và năng lượng đã dùng."
	unequip_button.tooltip_text = use_button.tooltip_text
	_label(panel,"Chọn đồ trong túi → chọn ô phù hợp → Trang bị. Mỗi tay/chân dùng một món riêng.",Rect2(12,299,592,14),8,MUTED)
	journal_panel = _root()
	_shade(journal_panel,0.7)
	panel = _panel(journal_panel,Rect2(52,28,536,304))
	_label(panel,"NHIỆM VỤ",Rect2(18,10,480,25),16,GOLD)
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
	hp_label.text = _group_int(current)+" / "+_group_int(maximum)
	var width: float = floorf(132.0 * clampf(float(current) / maxf(1.0, float(maximum)), 0.0, 1.0))
	hp_bar.size.x = width
	hp_bar.visible = width > 0
	health_crop.region = Rect2(0, 0, maxf(1.0, width), 5)
	hp_bar.modulate = Color.WHITE if current > maximum / 3 else Color("e6a28e")

func update_inventory(model: RefCounted) -> void:
	inventory_model = model
	for slot: String in equipment_buttons:
		var button: Button = equipment_buttons[slot]
		var id: String = str(model.equipment[slot])
		button.icon = null if id.is_empty() else _art_frame(_item_art(id),&"idle")
		button.size = Vector2(92,31)
		button.tooltip_text = button.text+": "+("Trống" if id.is_empty() else str(model.database[id].name))
		button.set_pressed_no_signal(slot == selected_equipment)
	equipment_preview.apply_equipment(model.equipment)
	equipment_damage.text = "Vũ khí: "+str(model.weapon_damage())+" sát thương"
	for i: int in range(16):
		var slot: Dictionary = model.slots[i]
		var button: Button = inventory_buttons[i]
		button.icon = null
		button.text = "·"
		button.tooltip_text = "Ô trống"
		if not slot.is_empty():
			var item: Dictionary = model.database[slot.id]
			var frames: SpriteFrames = _item_art(str(slot.id))
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
	inventory_detail.text = "Ô trống" if slot.is_empty() else str(inventory_model.database[slot.id].name)+" ×"+str(slot.count)+"\n"+str(inventory_model.database[slot.id].description)
	if not slot.is_empty():
		var item: Dictionary = inventory_model.database[slot.id]
		use_button.disabled = item.type != "consumable" and not inventory_model.allowed(str(slot.id),selected_equipment)
		use_button.text = "Dùng vật phẩm" if item.type == "consumable" else "Trang bị vào ô đã chọn"
	unequip_button.disabled = str(inventory_model.equipment[selected_equipment]).is_empty()

func select_equipment(slot: String) -> void:
	selected_equipment = slot
	for key: String in equipment_buttons: equipment_buttons[key].set_pressed_no_signal(key == slot)
	select_slot(selected_slot)
	var id: String = str(inventory_model.equipment[slot])
	if not id.is_empty(): inventory_detail.text = equipment_buttons[slot].text+" đang mặc: "+str(inventory_model.database[id].name)+"\nChọn Tháo để chuyển món này về túi."

func _activate_inventory_item() -> void:
	if inventory_model == null or inventory_model.slots[selected_slot].is_empty(): return
	var id: String = str(inventory_model.slots[selected_slot].id)
	if inventory_model.database[id].type == "consumable": item_use_requested.emit(selected_slot)
	else: equip_requested.emit(selected_slot,selected_equipment)

func show_inventory_error(message: String) -> void:
	inventory_detail.text = message

func update_quest(model: RefCounted) -> void:
	objective.text = "DƯ ÂM ĐẦU TIÊN\n"+model.objective_text()
	journal_text.text = str(model.definition.name)+" — "+{"available":"Chưa nhận","active":"Đang làm","completed":"Hoàn thành chặng rừng"}[model.status]+"\n\n"
	for i: int in range(model.definition.objectives.size()):
		journal_text.text += ("[✓] " if model.done(i) else "[  ] ")+str(model.definition.objectives[i].text)+"\n"
	journal_text.text += "\nThưởng: 2 thuốc hồi phục, 3 quặng ký ức.\n"+str(model.definition.description)

func _progression_bar(parent: Node, point: Vector2, frames: SpriteFrames) -> TextureRect:
	var track := TextureRect.new()
	track.position = point
	track.size = Vector2(132, 5)
	track.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	track.stretch_mode = TextureRect.STRETCH_KEEP
	track.texture = frames.get_frame_texture(&"idle", 0)
	track.modulate = Color(0.30, 0.30, 0.30, 1.0)
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(track)
	var bar := TextureRect.new()
	bar.position = point
	bar.size = Vector2(132, 5)
	bar.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bar.stretch_mode = TextureRect.STRETCH_KEEP
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var crop := AtlasTexture.new()
	crop.atlas = frames.get_frame_texture(&"idle", 0)
	crop.region = Rect2(0, 0, 132, 5)
	crop.filter_clip = true
	bar.texture = crop
	bar.set_meta(&"progression_crop", crop)
	bar.hide()
	parent.add_child(bar)
	progression_bars.append({"crop": crop, "frames": frames, "track": track})
	return bar

func _fill_progression_bar(bar: TextureRect, fraction: float) -> void:
	var width: float = floorf(132.0 * clampf(fraction, 0.0, 1.0))
	bar.size.x = width
	bar.visible = width > 0
	var crop: AtlasTexture = bar.get_meta(&"progression_crop")
	crop.region = Rect2(0, 0, maxf(1.0, width), 5)

func set_resources(energy: float, max_energy: float, stamina: float, max_stamina: float) -> void:
	energy_label.text = _group_int(int(floorf(maxf(0.0, energy)))) + " / " + _group_int(int(max_energy))
	stamina_label.text = _group_int(int(floorf(maxf(0.0, stamina)))) + " / " + _group_int(int(max_stamina))
	_fill_progression_bar(energy_bar, energy / maxf(1.0, max_energy))
	_fill_progression_bar(stamina_bar, stamina / maxf(1.0, max_stamina))
	energy_label.tooltip_text = "Năng lượng hiện tại / tối đa · Chuột phải dùng 20 khi không tương tác"
	stamina_label.tooltip_text = "Thể lực hiện tại / tối đa · Chạy dùng 18 mỗi giây"

func _build_character_panel() -> void:
	character_panel = _root()
	character_panel.name = "CharacterScreen"
	_shade(character_panel, 0.78)
	var panel := _panel(character_panel, Rect2(14, 36, 612, 312))
	panel.name = "StatsPanel"
	panel.add_theme_stylebox_override("panel", _art_style(STATS_PANEL_ART, &"idle"))
	character_title = _label(panel, "NHÂN VẬT", Rect2(16, 8, 338, 25), 16, GOLD)
	unspent_label = _label(panel, "—", Rect2(357, 12, 237, 20), 11, GOLD)
	unspent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	character_summary = _label(panel, "", Rect2(16, 35, 578, 20), 10, CREAM)
	_label(panel, "Mỗi lần:", Rect2(16, 61, 70, 20), 10, MUTED)
	for i: int in range(4):
		var amount: int = [1, 5, 10, 100][i]
		var button := _button(panel, str(amount), Rect2(88 + i * 52, 59, 45, 23), func() -> void: _set_allocation_batch(amount))
		button.name = "Batch" + str(amount)
		button.toggle_mode = true
		button.button_pressed = amount == allocation_batch
		button.tooltip_text = "Phân bổ " + str(amount) + " điểm mỗi lần"
		batch_buttons.append(button)
	for i: int in range(STAT_ROWS.size()):
		var spec: Dictionary = STAT_ROWS[i]
		var key: String = str(spec.key)
		var y: float = 80 + i * 24
		var name_label := _label(panel, str(spec.name), Rect2(16, y, 90, 27), 11, CREAM)
		name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var assigned := _label(panel, "—", Rect2(108, y, 62, 27), 10, GOLD)
		assigned.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		assigned.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var value := _label(panel, "—", Rect2(180, y, 144, 27), 9, CREAM)
		value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var description := _label(panel, str(spec.description), Rect2(327, y, 205, 27), 9, MUTED)
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		var button := _button(panel, "+1", Rect2(542, y + 1, 50, 25), func() -> void: _request_allocation(key))
		button.name = "Allocate" + key.capitalize()
		button.add_theme_font_size_override("font_size", 10)
		button.disabled = true
		stat_widgets[key] = {"allocated": assigned, "value": value, "button": button}
	_label(panel, "Điểm có tác dụng ngay · Tab / Enter chọn · E / Esc đóng hành trang", Rect2(16, 253, 578, 17), 9, MUTED)
	allocated_summary = _label(panel, "", Rect2(16, 284, 420, 19), 9, CREAM)
	character_close = _button(panel, "Đóng  [E / Esc]", Rect2(452, 279, 142, 25), overlay_close_requested.emit)
	character_close.name = "CharacterClose"
	# Tab order is predictable even when all allocation buttons are disabled.
	for i: int in range(batch_buttons.size()):
		var previous: Button = character_close if i == 0 else batch_buttons[i - 1]
		batch_buttons[i].focus_previous = batch_buttons[i].get_path_to(previous)

func _set_allocation_batch(amount: int) -> void:
	allocation_batch = amount
	for i: int in range(batch_buttons.size()):
		batch_buttons[i].set_pressed_no_signal([1, 5, 10, 100][i] == amount)
	if progression_model != null:
		update_progression(progression_model)

func _request_allocation(stat: String) -> void:
	if progression_model == null or int(progression_model.unspent_points) < allocation_batch:
		return
	allocate_stat_requested.emit(stat, allocation_batch)

func update_progression(model: RefCounted) -> void:
	progression_model = model
	var level: int = int(model.level)
	var experience: int = int(model.experience)
	var free: int = int(model.unspent_points)
	var maximum: bool = level >= 9999
	level_label.text = "LỮ KHÁCH · CẤP " + str(level) + (" · MAX" if maximum else "")
	character_title.text = "NHÂN VẬT · CẤP " + str(level)
	unspent_label.text = _group_int(free) + " điểm chưa phân bổ"
	if maximum:
		xp_label.text = "XP MAX"
		character_summary.text = "XP MAX · Đã đạt cấp 9999"
		_fill_progression_bar(xp_bar, 1.0)
	else:
		var required: int = int(model.xp_required())
		xp_label.text = "XP " + _group_int(experience) + " / " + _group_int(required)
		character_summary.text = "XP " + _group_int(experience) + " / " + _group_int(required) + " · Mỗi cấp nhận 5 điểm tự phân bổ"
		_fill_progression_bar(xp_bar, float(experience) / maxf(1.0, float(required)))
	xp_label.tooltip_text = character_summary.text
	var values: Dictionary = model.derived_stats()
	var allocated_total: int = 0
	for spec: Dictionary in STAT_ROWS:
		var key: String = str(spec.key)
		var row: Dictionary = stat_widgets[key]
		var allocated: int = int(model.allocated[key])
		allocated_total += allocated
		var assigned: Label = row.allocated
		assigned.text = _group_int(allocated) + " đ"
		var effect: Label = row.value
		effect.text = _stat_value(key, values)
		var button: Button = row.button
		button.text = "+" + str(allocation_batch)
		button.disabled = free < allocation_batch
		button.tooltip_text = ("Cần " + str(allocation_batch) + " điểm chưa phân bổ") if button.disabled else ("Thêm " + str(allocation_batch) + " điểm " + str(spec.name).to_lower() + "; áp dụng ngay")
	allocated_summary.text = "Đã phân bổ " + _group_int(allocated_total) + " · Còn " + _group_int(free) + " điểm"
	if character_panel.visible:
		var focused: Control = get_viewport().gui_get_focus_owner()
		if focused is Button and focused.disabled:
			batch_buttons[[1, 5, 10, 100].find(allocation_batch)].grab_focus()

func _stat_value(stat: String, values: Dictionary) -> String:
	match stat:
		"health": return _group_int(int(values.max_health)) + " HP tối đa"
		"energy": return _group_int(int(values.max_energy)) + " tối đa"
		"stamina": return _group_int(int(values.max_stamina)) + " tối đa"
		"speed": return "%.1f / %.1f px/s" % [values.walk_speed, values.run_speed]
		"luck": return "CM %.1f%% · XP +%.1f%%" % [float(values.crit_chance) * 100, float(values.xp_bonus) * 100]
		"strength": return _group_int(int(values.strength)) + " · +" + _group_int(int(values.damage_bonus)) + " sát thương"
		"defense": return _group_int(int(values.defense)) + " · −%.1f%%" % (float(values.damage_reduction) * 100)
	return ""

func _group_int(value: int) -> String:
	var digits: String = str(absi(value))
	var groups: PackedStringArray = []
	while digits.length() > 3:
		groups.insert(0, digits.right(3))
		digits = digits.left(digits.length() - 3)
	groups.insert(0, digits)
	return ("−" if value < 0 else "") + ",".join(groups)
