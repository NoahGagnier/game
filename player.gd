extends CharacterBody2D

signal health_depleted

var health = 100.0

func _physics_process(delta: float) -> void:
	var direction = Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = direction * 450
	move_and_slide()
	
	if velocity.length() > 0.0:
		%HappyBoo.play_walk_animation() #happyboo is actually a path to the file, but its on the same level and doesnt require a happy_boo/happyboo
	else:
		%HappyBoo.play_idle_animation()  # $ is shortcut for get_node

	const DAMAGE_RATE = 20.0 # 20 dmg per enemy per second
	var overlapping_mobs = %HurtBox.get_overlapping_bodies()
	if overlapping_mobs.size() > 0:
		health -= DAMAGE_RATE * overlapping_mobs.size() * delta
		%ProgressBar.value = health
		if health <= 0.0:
			health_depleted.emit()
