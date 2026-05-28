extends Area2D

const BEAM_LENGTH := 256.0
const BEAM_WIDTH := 20.0

@export var lifetime: float = 0.18
@export var animation_name: String = "default"

var _player: Player
var _knockback: float = 200.0
var _hit_targets: Array[Node] = []

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_play_beam_animation()
	for body in get_overlapping_bodies():
		_on_body_entered(body)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _play_beam_animation() -> void:
	if _sprite.sprite_frames == null:
		return
	if _sprite.sprite_frames.has_animation(animation_name):
		_sprite.play(animation_name)
	elif _sprite.sprite_frames.get_animation_names().size() > 0:
		_sprite.play(_sprite.sprite_frames.get_animation_names()[0])

func setup(origin: Vector2, direction: Vector2, player: Player, knockback: float = 200.0) -> void:
	var dir := direction.normalized()
	global_position = origin
	rotation = dir.angle()
	_player = player
	_knockback = knockback

func _on_body_entered(body: Node2D) -> void:
	if _player == null or body in _hit_targets:
		return
	if not body.has_method("take_damage"):
		return
	_hit_targets.append(body)
	var push_dir := (body.global_position - global_position).normalized()
	_player.deal_damage_to(body, push_dir, _player.holy_damage, _knockback, DamageKind.Type.HOLY)
