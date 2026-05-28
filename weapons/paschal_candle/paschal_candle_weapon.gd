class_name PaschalCandleWeapon
extends Node2D

@export var fireball_scene: PackedScene = preload("res://weapons/paschal_candle/paschal_fireball.tscn")
@export var orbit_radius: float = 80.0
@export var orbit_speed: float = 1.1
@export var fireball_knockback: float = 120.0
@export var hit_cooldown: float = 0.35

var player: Player
var _fireballs: Array[PaschalFireball] = []
var _time: float = 0.0

func bind_player(p: Player) -> void:
	player = p

func add_fireball() -> void:
	if fireball_scene == null:
		return
	var fireball := fireball_scene.instantiate() as PaschalFireball
	if fireball == null:
		return
	fireball.knockback = fireball_knockback
	fireball.hit_cooldown = hit_cooldown
	if player != null:
		fireball.bind_player(player)
	add_child(fireball)
	_fireballs.append(fireball)
	_update_fireball_positions()

func _process(delta: float) -> void:
	_time += delta
	_update_fireball_positions()

func _update_fireball_positions() -> void:
	var count := _fireballs.size()
	if count == 0:
		return
	for i in range(count):
		var phase := -_time * orbit_speed + TAU * float(i) / float(count)
		var pos := Vector2(cos(phase), sin(phase)) * orbit_radius
		_fireballs[i].position = pos
		_fireballs[i].z_index = 1 if pos.y > 0.0 else -1
