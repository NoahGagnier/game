extends CanvasLayer

const MAIN_MENU_SCENE := "res://menus/main_menu.tscn"

const FONT_NORMAL := Color(0.82, 0.78, 0.68)
const FONT_HIGHLIGHT := Color(1.0, 0.93, 0.55)

@onready var _resume_button: Button = $PausePanel/Center/VBox/ResumeButton
@onready var _main_menu_button: Button = $PausePanel/Center/VBox/MainMenuButton

var _paused: bool = false

func _ready() -> void:
	visible = false
	_resume_button.pressed.connect(_on_resume_pressed)
	_main_menu_button.pressed.connect(_on_main_menu_pressed)
	_bind_button_highlight(_resume_button)
	_bind_button_highlight(_main_menu_button)
	_resume_button.focus_neighbor_bottom = _resume_button.get_path_to(_main_menu_button)
	_main_menu_button.focus_neighbor_top = _main_menu_button.get_path_to(_resume_button)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("pause"):
		return
	if _paused:
		_resume()
	elif _can_pause():
		_pause()
	get_viewport().set_input_as_handled()

func _can_pause() -> bool:
	var game_over := get_parent().get_node_or_null("GameOver")
	if game_over != null and game_over.visible:
		return false
	return true

func _pause() -> void:
	_paused = true
	visible = true
	get_tree().paused = true
	var m := get_node_or_null("/root/MusicManager")
	if m != null:
		m.call("pause_music")
	_resume_button.grab_focus()

func _resume() -> void:
	_paused = false
	visible = false
	get_tree().paused = false
	var m := get_node_or_null("/root/MusicManager")
	if m != null:
		m.call("resume_music")

func _on_resume_pressed() -> void:
	_resume()

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _bind_button_highlight(button: Button) -> void:
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_color_override("font_color", FONT_NORMAL)
	button.add_theme_color_override("font_hover_color", FONT_HIGHLIGHT)
	button.add_theme_color_override("font_focus_color", FONT_HIGHLIGHT)
	button.add_theme_color_override("font_pressed_color", FONT_HIGHLIGHT)
