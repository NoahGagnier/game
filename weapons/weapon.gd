class_name Weapon
extends Node2D

# Each additional stack adds this fraction of the base damage. e.g. 0.5 = +50% per stack.
const STACK_DAMAGE_BONUS := 0.5

var weapon_id: String = ""
var incompatible_weapon_ids: Array[String] = []
var stack_count: int = 1

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

func stack() -> void:
	stack_count += 1

func get_damage_multiplier() -> float:
	return 1.0 + STACK_DAMAGE_BONUS * float(stack_count - 1)
