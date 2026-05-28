class_name HolyCruetWeapon
extends Weapon

@export var burst_scene: PackedScene = preload("res://weapons/holy_cruet/holy_circle_burst.tscn")
@export var fire_cooldown: float = 0.55
@export var burst_knockback: float = 180.0

var _cooldown_timer: float = 0.0

@onready var _circle_back: AnimatedSprite2D = $CircleBack
@onready var _circle_front: AnimatedSprite2D = $CircleFront

func _ready() -> void:
	weapon_id = "holy_cruet"
	incompatible_weapon_ids = ["blood_of_januarius"]
	pickup_scene = preload("res://loot/items/holy_cruet.tscn")

func _process(delta: float) -> void:
	_cooldown_timer = maxf(0.0, _cooldown_timer - delta)
	if _circle_front.frame != _circle_back.frame:
		_circle_front.frame = _circle_back.frame

func try_fire() -> bool:
	if player == null or _cooldown_timer > 0.0:
		return false
	_cooldown_timer = fire_cooldown
	_spawn_burst()
	return true

func _spawn_burst() -> void:
	var parent := player.get_parent()
	if parent == null or burst_scene == null:
		return
	var burst := burst_scene.instantiate() as HolyCircleBurst
	if burst == null:
		return
	parent.add_child(burst)
	burst.knockback = burst_knockback
	burst.setup(player)
