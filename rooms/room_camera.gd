extends Camera2D

@export var target_path: NodePath
@export var follow_zoom: Vector2 = Vector2(2, 2)
@export var smoothing_speed: float = 8.0
@export var smoothing_enabled: bool = false

var _target: Node2D

func _ready() -> void:
	if target_path != NodePath(""):
		_target = get_node_or_null(target_path) as Node2D
	zoom = follow_zoom
	position_smoothing_enabled = smoothing_enabled
	position_smoothing_speed = smoothing_speed
	snap_to_target()

# Called externally (e.g. after teleporting the player into the start room) to
# instantly recenter without smoothing.
func snap_to_target() -> void:
	if _target == null:
		return
	global_position = _target.global_position
	reset_smoothing()

func _process(_delta: float) -> void:
	if _target == null:
		return
	global_position = _target.global_position
