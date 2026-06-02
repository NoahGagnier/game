@tool
class_name RoomProp
extends StaticBody2D

## Place the root node at the trunk/base of the prop.
## The sprite renders upward from that point.
## The root position is also the Y-sort and collision anchor — they all stay in sync.

@export var texture: Texture2D
@export_file("*.png", "*.webp") var texture_path: String = "res://rooms/extras!/olive-tree-1.png"
@export var sprite_scale: float = 1.0

@export_group("Y-Sort")
## Use the sprite's back/north edge (top of texture bounds) for depth sorting.
## Turn on for wide props (pews, benches) when the root is north of the art.
@export var y_sort_use_sprite_back_edge: bool = false
@export var y_sort_extra: float = 0.0

@export_group("Shadow")
@export var shadow_enabled: bool = false
@export var shadow_color: Color = Color(0.0, 0.0, 0.0, 0.4)
@export_range(0.05, 1.0) var shadow_flatten: float = 0.375
@export var shadow_width_scale: float = 1.0
@export var shadow_offset: Vector2 = Vector2.ZERO

var _y_sort_shift_applied: float = 0.0

func _ready() -> void:
	if not Engine.is_editor_hint():
		collision_layer = 4  # prop layer (layer 3) — flying enemies skip this layer
	_update_sprite()

func _enter_tree() -> void:
	if not Engine.is_editor_hint():
		call_deferred("_update_sprite")

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		_update_sprite()

func _update_sprite() -> void:
	var sprite := get_node_or_null("Sprite") as Sprite2D
	if sprite == null:
		return
	if texture != null:
		sprite.texture = texture
	elif texture_path != "" and ResourceLoader.exists(texture_path):
		sprite.texture = load(texture_path) as Texture2D
	_apply_sprite_layout(sprite)
	_apply_y_sort(sprite)
	_update_shadow(sprite)

func _apply_sprite_layout(sprite: Sprite2D) -> void:
	if sprite.texture == null:
		return
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.centered = true
	sprite.offset = Vector2(0.0, -sprite.texture.get_height() * 0.5)

func _apply_y_sort(sprite: Sprite2D) -> void:
	if Engine.is_editor_hint():
		return
	if not _is_in_world_layer():
		_clear_y_sort_shift()
		return
	if not y_sort_use_sprite_back_edge or sprite.texture == null:
		_clear_y_sort_shift()
		return
	var h := sprite.texture.get_height() * absf(sprite.scale.y)
	var back_y := sprite.position.y + sprite.offset.y - h * 0.5 + y_sort_extra
	if is_equal_approx(back_y, _y_sort_shift_applied):
		return
	_clear_y_sort_shift()
	if is_equal_approx(back_y, 0.0):
		return
	position.y += back_y
	for child in get_children():
		if child is Node2D:
			(child as Node2D).position.y -= back_y
	_y_sort_shift_applied = back_y

func _clear_y_sort_shift() -> void:
	if is_equal_approx(_y_sort_shift_applied, 0.0):
		return
	position.y -= _y_sort_shift_applied
	for child in get_children():
		if child is Node2D:
			(child as Node2D).position.y += _y_sort_shift_applied
	_y_sort_shift_applied = 0.0

func _is_in_world_layer() -> bool:
	var node := get_parent()
	while node != null:
		if node.is_in_group("world"):
			return true
		node = node.get_parent()
	return false

func _update_shadow(sprite: Sprite2D) -> void:
	var shadow := get_node_or_null("Shadow") as Sprite2D
	if not shadow_enabled:
		if shadow != null:
			shadow.visible = false
		return
	if sprite.texture == null:
		return
	if shadow == null:
		shadow = Sprite2D.new()
		shadow.name = "Shadow"
		shadow.z_index = -1
		add_child(shadow)
		move_child(shadow, 0)
	shadow.visible = true
	shadow.texture = sprite.texture
	shadow.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	shadow.centered = sprite.centered
	shadow.offset = sprite.offset
	shadow.scale = Vector2(
		sprite.scale.x * shadow_width_scale,
		-sprite.scale.y * shadow_flatten
	)
	shadow.position = sprite.position + shadow_offset
	shadow.modulate = shadow_color
