class_name Door
extends StaticBody2D

const HORIZONTAL_SIZE := Vector2(80, 30)
const VERTICAL_SIZE := Vector2(30, 80)
const FRAME_COUNT := 4

@export var horizontal_phase_in: Texture2D
@export var horizontal_locked: Texture2D
@export var horizontal_phase_out: Texture2D
@export var vertical_phase_in: Texture2D
@export var vertical_locked: Texture2D
@export var vertical_phase_out: Texture2D

@export var phase_in_speed: float = 10.0
@export var locked_speed: float = 5.0
@export var phase_out_speed: float = 10.0

@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

var _is_opening: bool = false

func _ready() -> void:
	_sprite.animation_finished.connect(_on_animation_finished)

# Orients the door barrier based on which wall it's sitting in. N/S doors are
# horizontal bars, E/W are vertical bars.
func set_direction(direction: String) -> void:
	var horizontal := direction == "N" or direction == "S"
	var size := HORIZONTAL_SIZE if horizontal else VERTICAL_SIZE
	var phase_in := horizontal_phase_in if horizontal else vertical_phase_in
	var locked := horizontal_locked if horizontal else vertical_locked
	var phase_out := horizontal_phase_out if horizontal else vertical_phase_out

	_setup_frames(phase_in, locked, phase_out, size)

	var fresh := RectangleShape2D.new()
	fresh.size = size
	_collision.shape = fresh
	_sprite.play("phase_in")

func open() -> void:
	if _is_opening:
		return
	_is_opening = true
	set_deferred("collision_layer", 0)
	if _sprite.sprite_frames != null and _sprite.sprite_frames.has_animation("phase_out"):
		_sprite.play("phase_out")
	else:
		queue_free()

func _on_animation_finished() -> void:
	match _sprite.animation:
		"phase_in":
			_sprite.play("locked")
		"phase_out":
			queue_free()

func _setup_frames(
	phase_in_tex: Texture2D,
	locked_tex: Texture2D,
	phase_out_tex: Texture2D,
	frame_size: Vector2,
) -> void:
	var frames := SpriteFrames.new()
	if phase_in_tex != null:
		_add_sheet_frames(frames, "phase_in", phase_in_tex, frame_size, phase_in_speed, false)
	if locked_tex != null:
		_add_sheet_frames(frames, "locked", locked_tex, frame_size, locked_speed, true)
	if phase_out_tex != null:
		_add_sheet_frames(frames, "phase_out", phase_out_tex, frame_size, phase_out_speed, false)
	elif phase_in_tex != null:
		_add_reversed_sheet_frames(frames, "phase_out", phase_in_tex, frame_size, phase_out_speed, false)
	_sprite.sprite_frames = frames

func _add_sheet_frames(
	frames: SpriteFrames,
	anim_name: String,
	texture: Texture2D,
	size: Vector2,
	speed: float,
	loop: bool,
) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_loop(anim_name, loop)
	frames.set_animation_speed(anim_name, speed)
	for i in FRAME_COUNT:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(i * size.x, 0.0, size.x, size.y)
		frames.add_frame(anim_name, atlas)

func _add_reversed_sheet_frames(
	frames: SpriteFrames,
	anim_name: String,
	texture: Texture2D,
	size: Vector2,
	speed: float,
	loop: bool,
) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_loop(anim_name, loop)
	frames.set_animation_speed(anim_name, speed)
	for i in range(FRAME_COUNT - 1, -1, -1):
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(i * size.x, 0.0, size.x, size.y)
		frames.add_frame(anim_name, atlas)
