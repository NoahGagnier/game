class_name HeartPickup
extends Pickup

@export var heal_amount: float = 50.0

func apply(player: Player) -> void:
	player.heal(heal_amount)
