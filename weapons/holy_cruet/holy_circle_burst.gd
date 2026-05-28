class_name HolyCircleBurst
extends Area2D

@export var travel_distance: float = 300.0
@export var out_duration: float = 1.1
@export var dissipate_duration: float = 0.45
@export var min_scale: float = 0.2
@export var max_scale: float = 1.0
@export var knockback: float = 180.0
@export var animation_name: String = "default"

enum Phase { OUT, DISSIPATE }

var _player: Player
var _direction: Vector2 = Vector2.RIGHT
var _origin: Vector2 = Vector2.ZERO
var _out_target: Vector2 = Vector2.ZERO
var _phase: Phase = Phase.OUT
var _timer: float = 0.0
var _life_timer: float = 0.0
var _total_duration: float = 0.0
var _hit_targets: Array[Node] = []

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_play_burst_animation()
	_total_duration = out_duration + dissipate_duration
	_set_scale(min_scale)
	modulate.a = 1.0

func setup(player: Player) -> void:
	_player = player
	_direction = player.get_facing_vector()
	_origin = player.global_position
	_out_target = _origin + _direction * travel_distance
	global_position = _origin

func _play_burst_animation() -> void:
	if _sprite.sprite_frames == null:
		return
	if _sprite.sprite_frames.has_animation(animation_name):
		_sprite.play(animation_name)
	elif _sprite.sprite_frames.get_animation_names().size() > 0:
		_sprite.play(_sprite.sprite_frames.get_animation_names()[0])

func _process(delta: float) -> void:
	_timer += delta
	_life_timer += delta
	var life_t := clampf(_life_timer / _total_duration, 0.0, 1.0)
	_set_scale(lerpf(min_scale, max_scale, _ease_out_cubic(life_t)))

	match _phase:
		Phase.OUT:
			var t := clampf(_timer / out_duration, 0.0, 1.0)
			var eased := _ease_out_cubic(t)
			global_position = _origin.lerp(_out_target, eased)
			if t >= 1.0:
				global_position = _out_target
				_phase = Phase.DISSIPATE
				_timer = 0.0
				monitoring = false
		Phase.DISSIPATE:
			var t := clampf(_timer / dissipate_duration, 0.0, 1.0)
			modulate.a = 1.0 - t
			if t >= 1.0:
				queue_free()

func _ease_out_cubic(t: float) -> float:
	return 1.0 - pow(1.0 - t, 3.0)

func _set_scale(value: float) -> void:
	scale = Vector2(value, value)

func _on_body_entered(body: Node2D) -> void:
	if _player == null or body == _player or body in _hit_targets:
		return
	if not body.has_method("take_damage"):
		return
	_hit_targets.append(body)
	var push_dir := (body.global_position - global_position).normalized()
	_player.deal_damage_to(body, push_dir, _player.holy_damage, knockback, DamageKind.Type.HOLY)
