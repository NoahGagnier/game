extends Camera2D

@export var target_path: NodePath
@export var follow_zoom: Vector2 = Vector2(2.3, 2.3)

# How far ahead of the player the camera drifts (in world pixels before zoom).
@export var lookahead_distance: float = 70.0
# How quickly the lookahead offset builds / fades. Lower = lazier.
@export var lookahead_speed: float = 2.5
# How fast the camera base position catches up to the player. Lower = floatier.
@export var follow_speed: float = 8.0

var _target: Node2D
var _lookahead_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	if target_path != NodePath(""):
		_target = get_node_or_null(target_path) as Node2D
	zoom = follow_zoom
	position_smoothing_enabled = false
	snap_to_target()

func snap_to_target() -> void:
	if _target == null:
		return
	_lookahead_offset = Vector2.ZERO
	global_position = _target.global_position
	reset_smoothing()

func _process(delta: float) -> void:
	if _target == null:
		return

	# Read velocity from the player if available.
	var vel := Vector2.ZERO
	if _target is CharacterBody2D:
		vel = (_target as CharacterBody2D).velocity

	# Slide the offset toward the look-ahead target.
	var target_offset := Vector2.ZERO
	if vel.length() > 10.0:
		target_offset = vel.normalized() * lookahead_distance
	_lookahead_offset = _lookahead_offset.lerp(target_offset, lookahead_speed * delta)

	# Ease the camera toward player + offset.
	var desired := _target.global_position + _lookahead_offset
	global_position = global_position.lerp(desired, follow_speed * delta)
