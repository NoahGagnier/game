class_name ThornyCrown
extends Pickup

# Each crown adds knockback retaliation force. Enemies that hit the player are
# pushed back and take their normal hit-damage from the contact.
@export var thorn_knockback_bonus: float = 250.0

func apply(player: Player) -> void:
	player.thorn_knockback += thorn_knockback_bonus
