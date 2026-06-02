@tool
class_name RoomProp
extends StaticBody2D

## Place the root node at the trunk/base of the prop.
## The sprite renders upward from that point.
## The root position is also the Y-sort and collision anchor — they all stay in sync.

@export var texture: Texture2D
@export_file("*.png", "*.webp") var texture_path: String = "res://rooms/extras!/olive-tree-1.png"
@export var sprite_scale: float = 1.0

@export_group("Shadow")
@export var shadow_enabled: bool = false
@export var shadow_color: Color = Color(0.0, 0.0, 0.0, 0.4)
@export_range(0.05, 1.0) var shadow_flatten: float = 0.375
@export var shadow_width_scale: float = 1.0
@export var shadow_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	_update_sprite()

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
	_update_shadow(sprite)

func _apply_sprite_layout(sprite: Sprite2D) -> void:
	if sprite.texture == null:
		return
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.centered = true
	sprite.offset = Vector2(0.0, -sprite.texture.get_height() * 0.5)

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
