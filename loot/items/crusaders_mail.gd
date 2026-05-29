class_name CrusadersMail
extends Pickup

# Multiplicative physical damage boost. Stacks if multiple are collected.
@export var physical_damage_multiplier: float = 1.66

func apply(player: Player) -> void:
	player.physical_damage_multiplier *= physical_damage_multiplier
