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
	_fireballs.append(fireball)
	add_child.call_deferred(fireball)
	call_deferred("_update_fireball_positions")

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
		var fireball := _fireballs[i]
		fireball.position = pos
		fireball.z_index = 1 if pos.y > 0.0 else -1
		var tangent := Vector2(sin(phase), -cos(phase))
		if tangent.length_squared() > 0.0001:
			fireball.rotation = tangent.angle() + fireball.rotation_offset
