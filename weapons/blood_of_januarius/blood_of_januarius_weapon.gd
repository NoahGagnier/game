class_name BloodOfJanuariusWeapon
extends Weapon

const PICKUP_SCENE_PATH := "res://loot/items/blood_of_januarius.tscn"

@export var beam_scene: PackedScene = preload("res://weapons/blood_of_januarius/blood_beam.tscn")
@export var fire_cooldown: float = 0.45
@export var beam_knockback: float = 220.0
@export var base_damage: float = 30.0

var _cooldown_timer: float = 0.0

@onready var _circle_back: AnimatedSprite2D = $CircleBack
@onready var _circle_front: AnimatedSprite2D = $CircleFront

func _init() -> void:
	_configure_weapon()

func _ready() -> void:
	_configure_weapon()

func _configure_weapon() -> void:
	weapon_id = "blood_of_januarius"
	incompatible_weapon_ids.assign(["holy_cruet"])

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
	var damage := base_damage * get_damage_multiplier()
	beam.setup(player.global_position, direction, player, beam_knockback, damage)
