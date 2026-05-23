class_name ItemPopup
extends Control

# Displayed when a pickup is collected. Auto-dismisses after `display_duration`
# seconds with a fade in/out. Set `background_texture` in the inspector to
# apply a custom dialogue box PNG.

@export var display_duration: float = 5.0
@export var fade_duration: float = 0.4

@onready var _icon: TextureRect = $Panel/HBox/Icon
@onready var _name_label: Label = $Panel/HBox/VBox/NameLabel
@onready var _desc_label: RichTextLabel = $Panel/HBox/VBox/DescLabel

var _tween: Tween

func _ready() -> void:
	modulate.a = 0.0

func show_item(pickup_name: String, description: String, icon: Texture2D) -> void:
	_name_label.text = pickup_name
	_desc_label.text = description
	_icon.texture = icon
	_icon.visible = icon != null

	if _tween != null and _tween.is_valid():
		_tween.kill()
	modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, fade_duration)
	_tween.tween_interval(display_duration)
	_tween.tween_property(self, "modulate:a", 0.0, fade_duration)
