extends Area2D

## Speed in pixels/second.
@export var speed: float = 160.0
## Max travel distance before despawn.
@export var max_range: float = 900.0
## Damage dealt to the player on hit.
@export var damage: float = 12.0

var _direction: Vector2 = Vector2.RIGHT
var _travelled: float = 0.0

func setup(pos: Vector2, dir: Vector2, dmg: float) -> void:
	global_position = pos
	_direction = dir.normalized()
	damage = dmg
	rotation = _direction.angle()

func _physics_process(delta: float) -> void:
	var step := _direction * speed * delta
	position += step
	_travelled += step.length()
	if _travelled >= max_range:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage, global_position)
	queue_free()
