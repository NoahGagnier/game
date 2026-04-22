class_name Room
extends Node2D

enum RoomType { START, NORMAL, BOSS, TREASURE }

const ROOM_SIZE: int = 1024

@export var available_doors: Array[String] = ["N", "S", "E", "W"]
@export var room_type: RoomType = RoomType.NORMAL

func get_door_local_position(direction: String) -> Vector2:
	match direction:
		"N": return Vector2(ROOM_SIZE / 2.0, 0)
		"S": return Vector2(ROOM_SIZE / 2.0, ROOM_SIZE)
		"E": return Vector2(ROOM_SIZE, ROOM_SIZE / 2.0)
		"W": return Vector2(0, ROOM_SIZE / 2.0)
	return Vector2.ZERO

func has_door(direction: String) -> bool:
	return direction in available_doors

func get_door_signature() -> String:
	var parts := ["N", "S", "E", "W"].filter(func(d): return d in available_doors)
	return "".join(parts)
