@tool
extends Node2D

## Run with F6. Assign `room_scene`, pick a spawn mode, then play.

enum SpawnMode {
	PLAYTEST_MARKER,
	ROOM_PLAYER_SPAWN,
	ROOM_DOOR_N,
	ROOM_DOOR_S,
	ROOM_DOOR_E,
	ROOM_DOOR_W,
	ROOM_FIRST_DOOR,
	CUSTOM,
}

@export var room_scene: PackedScene
@export var spawn_enemies: bool = false
@export var show_hud: bool = true

@export_group("Spawn")
@export var spawn_mode: SpawnMode = SpawnMode.PLAYTEST_MARKER
@export var custom_spawn_position: Vector2 = Vector2(512, 512)
@export var door_inset: float = 80.0

const HUD_SCENE: PackedScene = preload("res://hud.tscn")
const DEFAULT_ROOM: PackedScene = preload("res://rooms/room_spawn_NSEW_01.tscn")

@onready var _world: Node2D = $World
@onready var _player: CharacterBody2D = $World/Player
@onready var _room_slot: Node2D = $RoomSlot
@onready var _playtest_spawn: Marker2D = $PlaytestSpawn
@onready var _camera: Camera2D = $RoomCamera

var _room: Node2D

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_boot_playtest()

func _boot_playtest() -> void:
	var scene := room_scene if room_scene != null else DEFAULT_ROOM
	_room = scene.instantiate()
	_room_slot.add_child(_room)

	if _room is Room:
		(_room as Room).spawn_enemies_on_ready = spawn_enemies

	var spawn_pos := _resolve_spawn_global(_room)
	_player.global_position = spawn_pos
	if _camera.has_method("snap_to_target"):
		_camera.snap_to_target()

	if show_hud:
		add_child(HUD_SCENE.instantiate())

func _resolve_spawn_global(room: Node) -> Vector2:
	match spawn_mode:
		SpawnMode.PLAYTEST_MARKER:
			return _playtest_spawn.global_position
		SpawnMode.ROOM_PLAYER_SPAWN:
			return _marker_global(room, "Spawns/PlayerSpawn")
		SpawnMode.ROOM_DOOR_N:
			return _door_spawn_global(room, "N")
		SpawnMode.ROOM_DOOR_S:
			return _door_spawn_global(room, "S")
		SpawnMode.ROOM_DOOR_E:
			return _door_spawn_global(room, "E")
		SpawnMode.ROOM_DOOR_W:
			return _door_spawn_global(room, "W")
		SpawnMode.ROOM_FIRST_DOOR:
			return _first_door_spawn_global(room)
		SpawnMode.CUSTOM:
			return room.global_position + custom_spawn_position
	return _playtest_spawn.global_position

func _marker_global(room: Node, path: String) -> Vector2:
	var marker := room.get_node_or_null(path) as Node2D
	if marker != null:
		return marker.global_position
	return room.global_position + Vector2(Room.ROOM_SIZE * 0.5, Room.ROOM_SIZE * 0.5)

func _door_spawn_global(room: Node, direction: String) -> Vector2:
	var marker := room.get_node_or_null("Doors/Door%s" % direction) as Node2D
	if marker != null:
		var center := Vector2(Room.ROOM_SIZE * 0.5, Room.ROOM_SIZE * 0.5)
		var toward_center := (center - marker.position).normalized()
		return room.global_position + marker.position + toward_center * door_inset
	return room.global_position + _door_local_with_inset(direction)

func _first_door_spawn_global(room: Node) -> Vector2:
	if room is Room:
		for direction in ["N", "S", "E", "W"]:
			if (room as Room).has_door(direction):
				return _door_spawn_global(room, direction)
	return _marker_global(room, "Spawns/PlayerSpawn")

func _door_local_with_inset(direction: String) -> Vector2:
	var half := Room.ROOM_SIZE * 0.5
	match direction:
		"N":
			return Vector2(half, door_inset)
		"S":
			return Vector2(half, Room.ROOM_SIZE - door_inset)
		"E":
			return Vector2(Room.ROOM_SIZE - door_inset, half)
		"W":
			return Vector2(door_inset, half)
	return Vector2(half, half)
