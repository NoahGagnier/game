extends Camera2D

@export var target_path: NodePath
@export var pan_duration: float = 0.25

var _target: Node2D
var _current_cell := Vector2i(2147483647, 2147483647)
var _tween: Tween

func _ready() -> void:
	if target_path != NodePath(""):
		_target = get_node_or_null(target_path) as Node2D
	snap_to_target()

# Re-snap immediately (used after programmatically moving the target, e.g.
# spawning the player into the start room).
func snap_to_target() -> void:
	_snap_to_target_cell()

func _process(_delta: float) -> void:
	if _target == null:
		return
	var cell := _cell_of(_target.global_position)
	if cell != _current_cell:
		_current_cell = cell
		_pan_to_cell(cell)

func _cell_of(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(world_pos.x / Room.ROOM_SIZE)),
		int(floor(world_pos.y / Room.ROOM_SIZE))
	)

func _cell_center(cell: Vector2i) -> Vector2:
	return Vector2(
		cell.x * Room.ROOM_SIZE + Room.ROOM_SIZE * 0.5,
		cell.y * Room.ROOM_SIZE + Room.ROOM_SIZE * 0.5
	)

func _snap_to_target_cell() -> void:
	if _target == null:
		return
	_current_cell = _cell_of(_target.global_position)
	global_position = _cell_center(_current_cell)

func _pan_to_cell(cell: Vector2i) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE)
	_tween.set_ease(Tween.EASE_IN_OUT)
	_tween.tween_property(self, "global_position", _cell_center(cell), pan_duration)
