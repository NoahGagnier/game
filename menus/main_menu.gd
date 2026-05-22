extends Control

# Standalone main menu scene. Not wired into the project's main_scene yet so
# regular play (F5) still drops straight into game.tscn for fast iteration.
# To test the full menu -> cutscene -> game flow, run this scene with F6.

const CUTSCENE_SCENE := "res://menus/cutscene.tscn"
const NEW_GAME_TEXTURE := preload("res://menus/art/newgame.png")
const NEW_GAME_HIGHLIGHT_TEXTURE := preload("res://menus/art/newgame-highlight.png")
const CONTINUE_TEXTURE := preload("res://menus/art/continue.png")
const CONTINUE_HIGHLIGHT_TEXTURE := preload("res://menus/art/continue-hover.png")
const SETTINGS_TEXTURE := preload("res://menus/art/settings.png")
const SETTINGS_HIGHLIGHT_TEXTURE := preload("res://menus/art/settings-hover.png")

# Main logo bob -- subtle drift.
@export var logo_bob_amplitude: float = 8.0
@export var logo_bob_speed: float = 0.6

# Accent layer bob -- a touch more movement so it reads as a separate element
# floating over the main logo.
@export var accent_bob_amplitude: float = 12.0
@export var accent_bob_speed: float = 0.6
# Phase offset (in cycles) so the accent doesn't bob perfectly in sync. 0.0 =
# moves in lockstep with the main logo (just with a bigger amplitude).
@export var accent_bob_phase: float = 0.0

@onready var _new_game_button: TextureButton = $NewGameButton
@onready var _continue_button: TextureButton = $ContinueButton
@onready var _settings_button: TextureButton = $SettingsButton
@onready var _logo: TextureRect = $Logo
@onready var _logo_accent: TextureRect = $LogoAccent

var _logo_base_y: float
var _accent_base_y: float
var _time: float = 0.0

func _ready() -> void:
	_new_game_button.pressed.connect(_on_new_game_pressed)
	_bind_button_visual(_new_game_button, NEW_GAME_TEXTURE, NEW_GAME_HIGHLIGHT_TEXTURE)
	_bind_button_visual(_continue_button, CONTINUE_TEXTURE, CONTINUE_HIGHLIGHT_TEXTURE)
	_bind_button_visual(_settings_button, SETTINGS_TEXTURE, SETTINGS_HIGHLIGHT_TEXTURE)
	_logo_base_y = _logo.position.y
	_accent_base_y = _logo_accent.position.y

func _unhandled_input(event: InputEvent) -> void:
	if get_viewport().gui_get_focus_owner() != null:
		return
	if event.is_action_pressed("ui_down"):
		_new_game_button.grab_focus()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	_time += delta
	_logo.position.y = _logo_base_y + sin(_time * TAU * logo_bob_speed) * logo_bob_amplitude
	_logo_accent.position.y = _accent_base_y + sin((_time + accent_bob_phase) * TAU * accent_bob_speed) * accent_bob_amplitude

func _bind_button_visual(button: TextureButton, normal_texture: Texture2D, highlight_texture: Texture2D) -> void:
	var visual := button.get_node("Visual") as TextureRect
	visual.texture = normal_texture
	button.mouse_entered.connect(func() -> void:
		visual.texture = highlight_texture
	)
	button.mouse_exited.connect(func() -> void:
		if not button.has_focus():
			visual.texture = normal_texture
	)
	button.focus_entered.connect(func() -> void:
		visual.texture = highlight_texture
	)
	button.focus_exited.connect(func() -> void:
		if not button.is_hovered():
			visual.texture = normal_texture
	)
	button.button_down.connect(func() -> void:
		visual.texture = highlight_texture
	)
	button.button_up.connect(func() -> void:
		if button.has_focus() or button.is_hovered():
			visual.texture = highlight_texture
		else:
			visual.texture = normal_texture
	)

func _on_new_game_pressed() -> void:
	get_tree().change_scene_to_file(CUTSCENE_SCENE)
