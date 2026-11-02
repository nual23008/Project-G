extends RefCounted
## Physical keys keep WASD stable across keyboard layouts.

static func configure() -> void:
	var bindings: Dictionary = {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_up": [KEY_W, KEY_UP], "move_down": [KEY_S, KEY_DOWN],
		"sprint": [KEY_SHIFT], "interact": [KEY_E],
		"pause_game": [KEY_ESCAPE], "fullscreen": [KEY_F11],
		"attack": [KEY_J], "inventory": [KEY_I], "journal": [KEY_Q],
		"quick_heal": [KEY_H], "save_game": [KEY_F5]
	}
	for action: String in bindings:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		for key: int in bindings[action]:
			var event := InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
	var mouse := InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	if not InputMap.action_has_event("attack",mouse):
		InputMap.action_add_event("attack",mouse)
