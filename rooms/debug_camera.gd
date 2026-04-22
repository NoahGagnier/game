extends Camera2D

@export var pan_speed: float = 2000.0
@export var zoom_step: float = 1.1
@export var min_zoom: float = 0.05
@export var max_zoom: float = 2.0

func _process(delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	# Divide by zoom so pan speed feels consistent when zoomed out.
	position += dir * pan_speed * delta / zoom.x

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_apply_zoom(zoom_step)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_apply_zoom(1.0 / zoom_step)

func _apply_zoom(factor: float) -> void:
	var z: float = clamp(zoom.x * factor, min_zoom, max_zoom)
	zoom = Vector2(z, z)
