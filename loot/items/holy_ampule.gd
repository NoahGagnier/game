class_name HolyAmpule
extends Pickup

# Each ampule stacks +15% dodge chance and spawns one orbiting shield orb on
# the player.
@export var dodge_chance_bonus: float = 0.15
@export var shield_scene: PackedScene = preload("res://loot/items/holy_ampule_shield.tscn")

const SHIELD_NODE_NAME := "HolyAmpuleShield"

func apply(player: Player) -> void:
	player.dodge_chance += dodge_chance_bonus

	var shield := player.get_node_or_null(SHIELD_NODE_NAME) as HolyAmpuleShield
	if shield == null:
		shield = shield_scene.instantiate() as HolyAmpuleShield
		shield.name = SHIELD_NODE_NAME
		player.add_child(shield)
	shield.add_orb()
