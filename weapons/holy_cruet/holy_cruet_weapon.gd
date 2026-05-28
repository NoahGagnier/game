class_name HolyCruetWeapon
extends Weapon

const PICKUP_SCENE_PATH := "res://loot/items/holy_cruet.tscn"

@export var burst_scene: PackedScene = preload("res://weapons/holy_cruet/holy_circle_burst.tscn")
@export var fire_cooldown: float = 0.55
@export var burst_knockback: float = 180.0
@export var base_damage: float = 30.0

var _cooldown_timer: float = 0.0

@onready var _circle_back: AnimatedSprite2D = $CircleBack
@onready var _circle_front: AnimatedSprite2D = $CircleFront

func _init() -> void:
	_configure_weapon()

func _ready() -> void:
	_configure_weapon()

func _configure_weapon() -> void:
	weapon_id = "holy_cruet"
	incompatible_weapon_ids.assign(["blood_of_januarius"])

func get_pickup_scene() -> PackedScene:
	return load(PICKUP_SCENE_PATH) as PackedScene

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
	burst.damage = base_damage * get_damage_multiplier()
	burst.setup(player)
