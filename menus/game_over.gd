extends "res://menus/cutscene.gd"

const MAIN_MENU_SCENE := "res://menus/main_menu.tscn"

const FONT_NORMAL := Color(0.82, 0.78, 0.68)
const FONT_HIGHLIGHT := Color(1.0, 0.93, 0.55)

@onready var _options_panel: Control = $OptionsPanel
@onready var _retry_button: Button = $OptionsPanel/Center/VBox/RetryButton
@onready var _main_menu_button: Button = $OptionsPanel/Center/VBox/MainMenuButton

var _showing_options: bool = false

func _ready() -> void:
	_options_panel.visible = false
	_retry_button.pressed.connect(_on_retry_pressed)
	_main_menu_button.pressed.connect(_on_main_menu_pressed)
	_bind_button_highlight(_retry_button)
	_bind_button_highlight(_main_menu_button)
	_retry_button.focus_neighbor_bottom = _retry_button.get_path_to(_main_menu_button)
	_main_menu_button.focus_neighbor_top = _main_menu_button.get_path_to(_retry_button)
	super._ready()

func _unhandled_input(event: InputEvent) -> void:
	if not _showing_options:
		return
	if get_viewport().gui_get_focus_owner() != null:
		return
	if event.is_action_pressed("ui_down") or event.is_action_pressed("ui_accept"):
		_retry_button.grab_focus()
		get_viewport().set_input_as_handled()

func _on_cutscene_complete() -> void:
	_static_display.visible = false
	_anim_display.visible = false
	_options_panel.visible = true
	_showing_options = true
	_label.text = ""
	_label.visible_characters = 0
	await _fade_to(0.0)
	_retry_button.grab_focus()

func _on_retry_pressed() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)

func _on_main_menu_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)

func _bind_button_highlight(button: Button) -> void:
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_color_override("font_color", FONT_NORMAL)
	button.add_theme_color_override("font_hover_color", FONT_HIGHLIGHT)
	button.add_theme_color_override("font_focus_color", FONT_HIGHLIGHT)
	button.add_theme_color_override("font_pressed_color", FONT_HIGHLIGHT)
