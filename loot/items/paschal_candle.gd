class_name PaschalCandle
extends Pickup

@export var starting_fireballs: int = 3
@export var weapon_scene: PackedScene = preload("res://weapons/paschal_candle/paschal_candle_weapon.tscn")

const WEAPON_NODE_NAME := "PaschalCandleWeapon"

func apply(player: Player) -> void:
	var weapon := player.get_node_or_null(WEAPON_NODE_NAME) as PaschalCandleWeapon
	if weapon == null:
		weapon = weapon_scene.instantiate() as PaschalCandleWeapon
		if weapon == null:
			return
		weapon.name = WEAPON_NODE_NAME
		player.add_child(weapon)
		weapon.bind_player(player)
		for i in starting_fireballs:
			weapon.add_fireball()
	else:
		weapon.add_fireball()
