class_name Weapon
extends Node2D

var weapon_id: String = ""
var incompatible_weapon_ids: Array[String] = []

var player: Player

func bind_player(p: Player) -> void:
	player = p

func try_fire() -> bool:
	return false

func get_pickup_scene() -> PackedScene:
	return null

func is_incompatible_with(other: Weapon) -> bool:
	if other == null:
		return false
	return weapon_id in other.incompatible_weapon_ids or other.weapon_id in incompatible_weapon_ids
