class_name HolyCruet
extends Pickup

@export var weapon_scene: PackedScene

func apply(player: Player) -> void:
	var weapon := weapon_scene.instantiate() as Weapon
	if weapon == null:
		return
	player.equip_weapon(weapon)
