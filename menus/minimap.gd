extends Control

# Draws a small grid of visited rooms in the top-right corner. Only rooms the
# player has actually stepped into appear -- unexplored cells stay hidden so
# the map fills in as you progress.

const ROOM_SIZE := 1024

@export var dungeon_path: NodePath = ^"../../Dungeon"
@export var player_path: NodePath = ^"../../Player"

@export_group("Appearance")
@export var cell_size: int = 14
@export var cell_padding: int = 2
@export var panel_color: Color = Color(0, 0, 0, 0.45)
@export var start_color: Color = Color(0.4, 0.85, 0.45)
@export var treasure_color: Color = Color(1.0, 0.85, 0.25)
@export var boss_color: Color = Color(0.85, 0.25, 0.25)
@export var normal_color: Color = Color(0.62, 0.62, 0.68)
@export var current_border: Color = Color(1, 1, 1, 0.95)
@export var current_border_thickness: float = 1.5

var _visited: Dictionary = {}
var _rooms: Dictionary = {}
var _current_cell: Vector2i = Vector2i.ZERO
var _dungeon: Node
var _player: Node2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	call_deferred("_setup")

func _setup() -> void:
	_dungeon = get_node_or_null(dungeon_path)
	_player = get_node_or_null(player_path) as Node2D
	_scan_rooms()
	queue_redraw()

func _process(_delta: float) -> void:
	if _player == null or _dungeon == null:
		_setup()
		return
	if _rooms.is_empty():
		_scan_rooms()
		if _rooms.is_empty():
			return
	var cell := _world_to_cell(_player.global_position)
	var redraw := false
	if cell != _current_cell:
		_current_cell = cell
		redraw = true
	if _rooms.has(cell) and not _visited.has(cell):
		_visited[cell] = true
		redraw = true
	if redraw:
		queue_redraw()

func _scan_rooms() -> void:
	if _dungeon == null:
		return
	_rooms.clear()
	for child in _dungeon.get_children():
		if child is Room:
			var cell := Vector2i(
				int(floor(child.position.x / float(ROOM_SIZE))),
				int(floor(child.position.y / float(ROOM_SIZE))),
			)
			_rooms[cell] = child

func _world_to_cell(pos: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(pos.x / float(ROOM_SIZE))),
		int(floor(pos.y / float(ROOM_SIZE))),
	)

func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), panel_color, true)
	if _visited.is_empty():
		return
	var step := cell_size + cell_padding
	var center := size * 0.5 - Vector2(cell_size, cell_size) * 0.5
	for cell in _visited.keys():
		var room: Room = _rooms.get(cell)
		if room == null:
			continue
		var rel: Vector2i = cell - _current_cell
		var pos := center + Vector2(rel.x, rel.y) * step
		var rect := Rect2(pos, Vector2(cell_size, cell_size))
		draw_rect(rect, _color_for(room.room_type), true)
		if cell == _current_cell:
			draw_rect(rect, current_border, false, current_border_thickness)

func _color_for(room_type: int) -> Color:
	match room_type:
		Room.RoomType.START: return start_color
		Room.RoomType.TREASURE: return treasure_color
		Room.RoomType.BOSS: return boss_color
		_: return normal_color
