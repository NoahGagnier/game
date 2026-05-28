class_name Fleam
extends Pickup

# Stacks: each fleam adds heal_per_hit to the player's lifesteal.
@export var heal_per_hit: float = 2.0

func apply(player: Player) -> void:
	player.heal_on_hit += heal_per_hit
