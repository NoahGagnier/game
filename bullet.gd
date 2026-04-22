extends Area2D

var travelled_distance = 0;

func _physics_process(delta):
	const SPEED = 1000.0
	const RANGE = 1200.0
	var direction = Vector2.RIGHT.rotated(rotation)
	position += direction * SPEED * delta # SPEED OF BULLET
	
	travelled_distance += SPEED * delta
	if travelled_distance > RANGE:
		queue_free() # destroy bullet after 1 frame

func _on_body_entered(body: Node2D) -> void:
	queue_free() # destroy bullet after 1 frame
	if body.has_method("take_damage"):
		var knockback_direction = Vector2.RIGHT.rotated(rotation)
		body.take_damage(knockback_direction, 500.0)
