class_name VirginsVeil
extends Pickup

# Health regenerated per second. Stacks if multiple veils are collected.
@export var regen_per_second: float = 3.0

func apply(player: Player) -> void:
	player.regen_rate += regen_per_second
