class_name BloodOfJanuarius
extends Pickup

@export var weapon_scene: PackedScene = preload("res://weapons/blood_of_januarius/blood_of_januarius_weapon.tscn")

func apply(player: Player) -> void:
	var weapon := weapon_scene.instantiate() as Weapon
	if weapon == null:
		return
	player.equip_weapon(weapon)
