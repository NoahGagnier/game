class_name ItemPopup
extends Control

# Displayed when a pickup is collected. Auto-dismisses after `display_duration`
# seconds with a fade in/out. Assign `panel_texture` in the inspector once your
# 9-patch PNG is ready (see assets/hud/).

@export var display_duration: float = 5.0
@export var fade_duration: float = 0.4
@export var panel_texture: Texture2D
@export var patch_margin_left: int = 32
@export var patch_margin_top: int = 32
@export var patch_margin_right: int = 32
@export var patch_margin_bottom: int = 32
@export var panel_border_scale: float = 3.0

@onready var _vbox: VBoxContainer = $VBox
@onready var _panel: Control = $VBox/Panel
@onready var _margin_container: MarginContainer = $VBox/Panel/MarginContainer
@onready var _content_row: HBoxContainer = $VBox/Panel/MarginContainer/HBox
@onready var _background: NinePatchRect = $VBox/Panel/Background
@onready var _icon_slot: Control = $VBox/Panel/MarginContainer/HBox/IconSlot
@onready var _icon_shadow: TextureRect = $VBox/Panel/MarginContainer/HBox/IconSlot/IconShadow
@onready var _icon: TextureRect = $VBox/Panel/MarginContainer/HBox/IconSlot/Icon
@onready var _name_label: Label = $VBox/NameLabel
@onready var _desc_label: RichTextLabel = $VBox/Panel/MarginContainer/HBox/DescLabel

var _tween: Tween

func _ready() -> void:
	modulate.a = 0.0
	_apply_panel_texture()
	_panel.resized.connect(_update_background_scale)
	call_deferred("_update_panel_layout")

func _update_panel_layout() -> void:
	var margin_top := _margin_container.get_theme_constant("margin_top")
	var margin_bottom := _margin_container.get_theme_constant("margin_bottom")
	var margin_left := _margin_container.get_theme_constant("margin_left")
	var margin_right := _margin_container.get_theme_constant("margin_right")
	var content_size := _content_row.get_combined_minimum_size()
	_panel.custom_minimum_size = content_size + Vector2(
		margin_left + margin_right,
		margin_top + margin_bottom
	)
	_update_background_scale()
	call_deferred("_update_root_layout")

func _update_root_layout() -> void:
	var content_height := _vbox.get_combined_minimum_size().y
	if content_height <= 0.0:
		return
	offset_top = offset_bottom - content_height

func _update_background_scale() -> void:
	if panel_texture == null:
		return
	var panel_size := _panel.size
	if panel_size.x <= 0.0 or panel_size.y <= 0.0:
		return
	_background.scale = Vector2(panel_border_scale, panel_border_scale)
	_background.size = panel_size / panel_border_scale
	_background.position = Vector2.ZERO

func _apply_panel_texture() -> void:
	if panel_texture == null:
		return
	_background.texture = panel_texture
	_background.modulate = Color.WHITE
	_background.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_background.patch_margin_left = patch_margin_left
	_background.patch_margin_top = patch_margin_top
	_background.patch_margin_right = patch_margin_right
	_background.patch_margin_bottom = patch_margin_bottom
	_update_background_scale()

func show_item(pickup_name: String, description: String, icon: Texture2D, icon_ui_shadow: bool = false) -> void:
	_name_label.text = pickup_name
	_desc_label.text = description
	_apply_icon(icon, icon_ui_shadow)
	call_deferred("_update_panel_layout")

	if _tween != null and _tween.is_valid():
		_tween.kill()
	modulate.a = 0.0
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", 1.0, fade_duration)
	_tween.tween_interval(display_duration)
	_tween.tween_property(self, "modulate:a", 0.0, fade_duration)

func _apply_icon(icon: Texture2D, icon_ui_shadow: bool) -> void:
	var has_icon := icon != null
	_icon_slot.visible = has_icon
	_icon.visible = has_icon
	_icon_shadow.visible = has_icon and icon_ui_shadow
	if not has_icon:
		return

	_icon.texture = icon
	if icon_ui_shadow:
		_icon_shadow.texture = icon
