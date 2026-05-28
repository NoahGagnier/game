class_name FootOfMagdalane
extends Pickup

# Multiplicative speed boost. Stacks if multiple feet are collected (each one
# applies to the already-boosted speed).
@export var speed_multiplier: float = 1.15

func apply(player: Player) -> void:
	player.move_speed *= speed_multiplier
