class_name PaschalFireball
extends Area2D

@export var knockback: float = 120.0
@export var hit_cooldown: float = 0.35
@export var animation_fps: float = 8.0
## Extra rotation (radians) if the art needs a tweak. Tail-left art faces +X at 0.
@export var rotation_offset: float = 0.0
## How far below the fireball (in local pixels) the shadow sits. Larger
## values make the fireball look like it's hovering higher off the ground.
@export var shadow_drop: float = 8.0

var player: Player
var _cooldowns: Dictionary = {}
var _anim_time: float = 0.0

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _shadow: Sprite2D = $Shadow

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func bind_player(p: Player) -> void:
	player = p

func _process(delta: float) -> void:
	_anim_time += delta
	if _sprite.hframes > 1:
		_sprite.frame = int(_anim_time * animation_fps) % _sprite.hframes
	if _shadow != null:
		_shadow.frame = _sprite.frame
		# Counter the Area2D's rotation so the shadow stays flat on the
		# ground while the fireball still aims down its travel direction.
		_shadow.position = Vector2(0.0, shadow_drop).rotated(-rotation)
		_shadow.rotation = -rotation
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
