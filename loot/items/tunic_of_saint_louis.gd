class_name TunicOfSaintLouis
extends Pickup

# Multiplicative holy damage boost. Stacks if multiple tunics are collected.
@export var holy_damage_multiplier: float = 1.3

func apply(player: Player) -> void:
	player.holy_damage_multiplier *= holy_damage_multiplier
