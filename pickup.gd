class_name Pickup
extends Area2D

signal picked_up(pickup: Pickup)

@export var pop_height: float = 40.0
@export var pop_duration: float = 0.45

var _popping: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
	if _popping:
		return
	if body is Player:
		apply(body)
		picked_up.emit(self)
		queue_free()

# Override in subclasses to define the pickup's effect.
func apply(_player: Player) -> void:
	pass

# Arcs from current position to `target` over `pop_duration` seconds. The
# pickup cannot be collected while it's still in the air.
func pop_to(target: Vector2) -> void:
	_popping = true
	var start := global_position
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_method(
		func(t: float) -> void:
			var flat := start.lerp(target, t)
			var arc_y := -4.0 * pop_height * t * (1.0 - t)
			global_position = flat + Vector2(0.0, arc_y),
		0.0, 1.0, pop_duration
	)
	tween.tween_callback(func() -> void:
		_popping = false
	)
