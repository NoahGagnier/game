extends Control

# Plays the intro cutscene video, then transitions to the main game scene.
# - Plays automatically on scene load.
# - Player can press Esc, Enter, or click "Skip" to bail out early.
# - On video finish (or skip), loads game.tscn.

const GAME_SCENE := "res://game.tscn"

@onready var _video: VideoStreamPlayer = $VideoStreamPlayer
@onready var _skip_button: Button = $SkipButton

var _finished: bool = false

func _ready() -> void:
	_video.finished.connect(_finish)
	_skip_button.pressed.connect(_finish)
	if _video.stream != null:
		_video.play()
	else:
		push_warning("Cutscene has no video stream assigned; skipping straight to game.")
		_finish()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("ui_accept"):
		_finish()

func _finish() -> void:
	if _finished:
		return
	_finished = true
	get_tree().change_scene_to_file(GAME_SCENE)
