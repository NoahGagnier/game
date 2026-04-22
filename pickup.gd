class_name Pickup
extends Area2D

signal picked_up(pickup: Pickup)

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if body is Player:
		apply(body)
		picked_up.emit(self)
		queue_free()

# Override in subclasses to define the pickup's effect.
func apply(_player: Player) -> void:
	pass
