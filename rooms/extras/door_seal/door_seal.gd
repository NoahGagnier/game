@tool
class_name DoorSeal
extends StaticBody2D

## Blocks unused doorways. By default uses the same phase-in / locked door sheets as
## room lock doors (N/S = horizontal, E/W = vertical). Nudge sprite_offset to align.

@export var direction: String = "N":
	set(value):
		direction = value
		_queue_refresh()

@export_group("Door art")
@export var use_door_art: bool = true:
	set(value):
		use_door_art = value
		_queue_refresh()
@export var horizontal_phase_in: Texture2D = preload("res://rooms/door art/doorlock-h-phasein.png")
@export var horizontal_locked: Texture2D = preload("res://rooms/door art/doorlock-h.png")
@export var vertical_phase_in: Texture2D = preload("res://rooms/door art/doorlock-v-phasein.png")
@export var vertical_locked: Texture2D = preload("res://rooms/door art/doorlock-v.png")
@export var phase_in_speed: float = 10.0:
	set(value):
		phase_in_speed = value
		_queue_refresh()
@export var locked_speed: float = 5.0:
	set(value):
		locked_speed = value
		_queue_refresh()
@export var play_phase_in_on_spawn: bool = true

@export_group("Custom textures (optional)")
@export var texture_n: Texture2D
@export var texture_e: Texture2D
@export var texture_s: Texture2D
@export var texture_w: Texture2D
@export var use_room_background_fallback: bool = false:
	set(value):
		use_room_background_fallback = value
		_queue_refresh()

@export_group("Layout")
@export var sprite_scale: Vector2 = Vector2(2.0, 2.0):
	set(value):
		sprite_scale = value
		_queue_refresh()
@export var sprite_offset: Vector2 = Vector2.ZERO:
	set(value):
		sprite_offset = value
		_queue_refresh()
@export var collision_size_h: Vector2 = Vector2(80, 30):
	set(value):
		collision_size_h = value
		_queue_refresh()
@export var collision_size_v: Vector2 = Vector2(30, 80):
	set(value):
		collision_size_v = value
		_queue_refresh()

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _collision: CollisionShape2D = $CollisionShape2D

var _fallback_wall_texture: Texture2D
var _refresh_pending: bool = false
var _anim_hooked: bool = false

func _ready() -> void:
	if not Engine.is_editor_hint():
		collision_layer = 1
		collision_mask = 0
	_hook_animation()
	_refresh()

func setup(dir: String, wall_texture: Texture2D = null) -> void:
	direction = dir
	_fallback_wall_texture = wall_texture
	_refresh()

func _hook_animation() -> void:
	if _anim_hooked or _sprite == null:
		return
	_anim_hooked = true
	_sprite.animation_finished.connect(_on_animation_finished)

func _on_animation_finished() -> void:
	if _sprite.animation == "phase_in":
		_sprite.play("locked")

func _queue_refresh() -> void:
	if not is_inside_tree():
		return
	if _refresh_pending:
		return
	_refresh_pending = true
	call_deferred("_refresh")

func _refresh() -> void:
	_refresh_pending = false
	if _sprite == null:
		return
	_hook_animation()
	_apply_sprite_frames()
	_apply_layout()
	_play_visual()

func _apply_sprite_frames() -> void:
	var horizontal := direction == "N" or direction == "S"
	var frame_size := _frame_size_for_layout(horizontal)

	if use_door_art:
		var phase_in := horizontal_phase_in if horizontal else vertical_phase_in
		var locked := horizontal_locked if horizontal else vertical_locked
		_sprite.sprite_frames = Door.build_sprite_frames(
			phase_in,
			locked,
			null,
			frame_size,
			phase_in_speed,
			locked_speed,
			10.0,
			false,
		)
		_sprite.scale = sprite_scale
		return

	var custom := _texture_for_direction(direction)
	if custom != null:
		_sprite.sprite_frames = Door.build_static_frame_frames(custom)
		_sprite.scale = sprite_scale
		return

	if use_room_background_fallback and _fallback_wall_texture != null:
		var atlas_tex := _make_region_texture(_fallback_wall_texture, direction)
		_sprite.sprite_frames = Door.build_static_frame_frames(atlas_tex)
		var s := maxf(
			absf(_get_room_background_scale_hint()),
			maxf(absf(sprite_scale.x), absf(sprite_scale.y)),
		)
		_sprite.scale = Vector2(s, s)
		return

	_sprite.sprite_frames = null

func _play_visual() -> void:
	if _sprite.sprite_frames == null:
		return
	if Engine.is_editor_hint():
		if _sprite.sprite_frames.has_animation("locked"):
			_sprite.play("locked")
		return
	if play_phase_in_on_spawn and _sprite.sprite_frames.has_animation("phase_in"):
		_sprite.play("phase_in")
	elif _sprite.sprite_frames.has_animation("locked"):
		_sprite.play("locked")

func _frame_size_for_layout(horizontal: bool) -> Vector2:
	if use_door_art:
		return Door.HORIZONTAL_SIZE if horizontal else Door.VERTICAL_SIZE
	return collision_size_h if horizontal else collision_size_v

func _get_room_background_scale_hint() -> float:
	var room := get_parent() as Room
	if room == null:
		return sprite_scale.x
	var bg := room.get_node_or_null("Background") as Sprite2D
	if bg == null:
		return sprite_scale.x
	return maxf(absf(bg.scale.x), absf(bg.scale.y))

func _texture_for_direction(dir: String) -> Texture2D:
	match dir:
		"N":
			return texture_n
		"E":
			return texture_e
		"S":
			return texture_s
		"W":
			return texture_w
	return null

func _apply_layout() -> void:
	var horizontal := direction == "N" or direction == "S"
	var size := _frame_size_for_layout(horizontal)
	var shape := _collision.shape as RectangleShape2D
	if shape == null:
		shape = RectangleShape2D.new()
		_collision.shape = shape
	shape.size = size

	var base_sprite_pos := Vector2.ZERO
	match direction:
		"N":
			position = Vector2(Room.ROOM_SIZE * 0.5, 0.0)
			base_sprite_pos = Vector2(0.0, -size.y * 0.25)
		"S":
			position = Vector2(Room.ROOM_SIZE * 0.5, Room.ROOM_SIZE)
			base_sprite_pos = Vector2(0.0, size.y * 0.25)
		"E":
			position = Vector2(Room.ROOM_SIZE, Room.ROOM_SIZE * 0.5)
			base_sprite_pos = Vector2(size.x * 0.25, 0.0)
		"W":
			position = Vector2(0.0, Room.ROOM_SIZE * 0.5)
			base_sprite_pos = Vector2(-size.x * 0.25, 0.0)

	_sprite.flip_h = false
	_sprite.flip_v = false
	_sprite.rotation = 0.0
	_sprite.position = base_sprite_pos + sprite_offset
	_sprite.z_index = -9
	_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_sprite.centered = true

static func _make_region_texture(source: Texture2D, dir: String) -> Texture2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = source
	atlas.region = _region_for_direction(source, dir)
	return atlas

static func _region_for_direction(tex: Texture2D, dir: String) -> Rect2:
	var w := float(tex.get_width())
	var h := float(tex.get_height())
	var cx := w * 0.5
	var door_w := w * (96.0 / 512.0)
	var strip_h := h * (64.0 / 512.0)
	var strip_w := w * (64.0 / 512.0)
	match dir:
		"N":
			return Rect2(cx - door_w * 0.5, 0.0, door_w, strip_h)
		"S":
			return Rect2(cx - door_w * 0.5, h - strip_h, door_w, strip_h)
		"E":
			return Rect2(w - strip_w, cx - door_w * 0.5, strip_w, door_w)
		"W":
			return Rect2(0.0, cx - door_w * 0.5, strip_w, door_w)
	return Rect2()
