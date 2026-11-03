extends Node
## GNOME suppresses touchpad motion during WASD. Release that native typing
## guard for this game process, then restore the user's preference on exit.
var restore_typing_guard: bool = false
const SETTINGS: String = "/usr/bin/gsettings"
const SCHEMA: String = "org.gnome.desktop.peripherals.touchpad"
const KEY: String = "disable-while-typing"

func _ready() -> void:
	if OS.get_name() != "Linux" or DisplayServer.get_name() == "headless" or OS.get_cmdline_args().has("--script"):
		set_meta(&"skip_desktop",true)
		return
	if not FileAccess.file_exists(SETTINGS) or not OS.get_environment("XDG_CURRENT_DESKTOP").to_lower().contains("gnome"):
		set_meta(&"skip_desktop",true)
		return
	_enable_pointer()

func _enable_pointer() -> void:
	if has_meta(&"skip_desktop") or restore_typing_guard: return
	var output: Array = []
	if OS.execute(SETTINGS,["get",SCHEMA,KEY],output) == 0 and not output.is_empty() and str(output[0]).strip_edges() == "true":
		restore_typing_guard = OS.execute(SETTINGS,["set",SCHEMA,KEY,"false"]) == 0

func _restore_pointer() -> void:
	if restore_typing_guard:
		OS.execute(SETTINGS,["set",SCHEMA,KEY,"true"])
		restore_typing_guard = false

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN and is_node_ready(): _enable_pointer()

func _exit_tree() -> void:
	_restore_pointer()
