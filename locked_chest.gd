class_name LockedChest
extends Chest

# A chest that requires Keys to open. Inherits all loot/drop behavior from
# Chest -- the only difference is the interact check.

## Number of Keys consumed when the player opens this chest.
@export var key_cost: int = 1

func _unhandled_input(event: InputEvent) -> void:
	if is_open or not _player_in_range:
		return
	if not event.is_action_pressed("interact"):
		return
	var player := get_tree().get_first_node_in_group("player") as Player
	if player == null:
		return
	if player.keys < key_cost:
		_play_animation("closed")
		return
	player.keys -= key_cost
	open()
