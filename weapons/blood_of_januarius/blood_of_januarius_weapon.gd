class_name BloodOfJanuariusWeapon
extends Weapon

@export var beam_scene: PackedScene = preload("res://weapons/blood_of_januarius/blood_beam.tscn")
@export var fire_cooldown: float = 0.45
@export var beam_knockback: float = 220.0

var _cooldown_timer: float = 0.0

@onready var _circle_back: AnimatedSprite2D = $CircleBack
@onready var _circle_front: AnimatedSprite2D = $CircleFront

func _process(delta: float) -> void:
	_cooldown_timer = maxf(0.0, _cooldown_timer - delta)
	if _circle_front.frame != _circle_back.frame:
		_circle_front.frame = _circle_back.frame

func try_fire() -> bool:
	if player == null or _cooldown_timer > 0.0:
		return false
	_cooldown_timer = fire_cooldown
	_spawn_beam()
	return true

func _spawn_beam() -> void:
	var parent := player.get_parent()
	if parent == null or beam_scene == null:
		return
	var beam := beam_scene.instantiate() as Area2D
	if beam == null:
		return
	parent.add_child(beam)
	var direction := player.get_facing_vector()
	beam.setup(player.global_position, direction, player, beam_knockback)
