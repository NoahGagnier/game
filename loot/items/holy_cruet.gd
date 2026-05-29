class_name HolyCruet
extends Pickup

const WEAPON_SCENE_PATH := "res://weapons/holy_cruet/holy_cruet_weapon.tscn"

@export var weapon_scene: PackedScene

func apply(player: Player) -> void:
	var scene := _get_weapon_scene()
	if scene == null:
		return
	var weapon := scene.instantiate() as Weapon
	if weapon == null:
		return
	player.equip_weapon(weapon)

func _get_weapon_scene() -> PackedScene:
	if weapon_scene != null:
		return weapon_scene
	return load(WEAPON_SCENE_PATH) as PackedScene
