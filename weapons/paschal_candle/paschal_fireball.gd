class_name PaschalFireball
extends Area2D

@export var knockback: float = 120.0
@export var hit_cooldown: float = 0.35
@export var animation_fps: float = 8.0

var player: Player
var _cooldowns: Dictionary = {}
var _anim_time: float = 0.0

@onready var _sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func bind_player(p: Player) -> void:
	player = p

func _process(delta: float) -> void:
	_anim_time += delta
	if _sprite.hframes > 1:
		_sprite.frame = int(_anim_time * animation_fps) % _sprite.hframes
	for id in _cooldowns.keys():
		_cooldowns[id] -= delta
		if _cooldowns[id] <= 0.0:
			_cooldowns.erase(id)

func _on_body_entered(body: Node2D) -> void:
	if player == null or body == player:
		return
	if not body.has_method("take_damage"):
		return
	var id := body.get_instance_id()
	if _cooldowns.get(id, 0.0) > 0.0:
		return
	_cooldowns[id] = hit_cooldown
	var push_dir := (body.global_position - global_position).normalized()
	player.deal_damage_to(body, push_dir, player.holy_damage, knockback, DamageKind.Type.HOLY)
