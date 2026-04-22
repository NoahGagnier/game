class_name Door
extends StaticBody2D

const HORIZONTAL_SIZE := Vector2(80, 28)
const VERTICAL_SIZE := Vector2(28, 80)

@onready var _collision: CollisionShape2D = $CollisionShape2D
@onready var _visual: ColorRect = $Visual

# Orients the door barrier based on which wall it's sitting in. N/S doors are
# horizontal bars, E/W are vertical bars.
func set_direction(direction: String) -> void:
	var size: Vector2 = HORIZONTAL_SIZE if direction == "N" or direction == "S" else VERTICAL_SIZE
	var fresh := RectangleShape2D.new()
	fresh.size = size
	_collision.shape = fresh
	_visual.size = size
	_visual.position = -size / 2.0
