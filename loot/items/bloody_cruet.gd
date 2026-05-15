class_name BloodyCruet
extends Pickup

@export var max_health_increase: float = 50.0

func apply(player: Player) -> void:
	player.increase_max_health(max_health_increase)
