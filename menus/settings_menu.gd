extends Control

## Settings popup — volume sliders for Music and SFX.
## Persists values via ProjectSettings/AudioServer bus volumes.

const MUSIC_BUS := "Music"
const SFX_BUS := "SFX"

@onready var _music_slider: HSlider = $Panel/VBox/MusicRow/MusicSlider
@onready var _sfx_slider: HSlider = $Panel/VBox/SfxRow/SfxSlider
@onready var _close_button: Button = $Panel/VBox/CloseButton

func _ready() -> void:
	_music_slider.value = _bus_volume_linear(MUSIC_BUS)
	_sfx_slider.value = _bus_volume_linear(SFX_BUS)
	_music_slider.value_changed.connect(_on_music_changed)
	_sfx_slider.value_changed.connect(_on_sfx_changed)
	_close_button.pressed.connect(_on_close)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		_on_close()
		get_viewport().set_input_as_handled()

func _on_music_changed(value: float) -> void:
	_set_bus_volume(MUSIC_BUS, value)

func _on_sfx_changed(value: float) -> void:
	_set_bus_volume(SFX_BUS, value)

func _on_close() -> void:
	queue_free()

func _bus_volume_linear(bus_name: String) -> float:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return 1.0
	return db_to_linear(AudioServer.get_bus_volume_db(idx))

func _set_bus_volume(bus_name: String, linear: float) -> void:
	var idx := AudioServer.get_bus_index(bus_name)
	if idx == -1:
		return
	AudioServer.set_bus_volume_db(idx, linear_to_db(linear))
