class_name KeyPickup
extends Pickup

# A rare key dropped by enemies. Counted on the player for later use
# (locked doors, special chests, etc).

@export var amount: int = 1

func apply(player: Player) -> void:
	player.add_keys(amount)
