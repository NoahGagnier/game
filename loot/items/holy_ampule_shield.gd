class_name HolyAmpuleShield
extends Node2D

# Container that orbits N shield sprites around the player to indicate that
# dodge chance is active. Call add_orb() to grow the ring; it re-spaces all
# existing orbs evenly around the orbit.

@export var shield_texture: Texture2D
@export var orbit_radius: float = 28.0
@export var orbit_speed: float = 1.4
@export var bob_amplitude: float = 2.0
@export var bob_speed: float = 2.0
@export var flash_color: Color = Color(3.0, 3.0, 3.0, 1.0)
@export var flash_count: int = 4
@export var flash_interval: float = 0.06

var _orbs: Array[Sprite2D] = []
var _time: float = 0.0
var _flash_tween: Tween

func add_orb() -> void:
	var s := Sprite2D.new()
	s.texture = shield_texture
	add_child(s)
	_orbs.append(s)

func flash() -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_flash_tween = create_tween()
	for i in range(flash_count):
		_flash_tween.tween_callback(_set_orbs_modulate.bind(flash_color))
		_flash_tween.tween_interval(flash_interval)
		_flash_tween.tween_callback(_set_orbs_modulate.bind(Color.WHITE))
		_flash_tween.tween_interval(flash_interval)

func _set_orbs_modulate(c: Color) -> void:
	for o in _orbs:
		o.modulate = c

func _process(delta: float) -> void:
	_time += delta
	var count := _orbs.size()
	if count == 0:
		return
	for i in range(count):
		var phase := _time * orbit_speed + TAU * float(i) / float(count)
		var bob := sin(_time * bob_speed + float(i)) * bob_amplitude
		_orbs[i].position = Vector2(
			cos(phase) * orbit_radius,
			sin(phase) * orbit_radius + bob
		)
