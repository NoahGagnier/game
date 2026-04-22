class_name Player
extends CharacterBody2D

signal health_depleted

@export var max_health: float = 100.0
@export var move_speed: float = 450.0
@export var invincibility_time: float = 0.5
@export var hurt_time: float = 0.25
@export var shoot_time: float = 0.2
@export var contact_damage_taken: float = 20.0
@export var melee_knockback: float = 400.0

enum State { IDLE, WALK, SHOOT, HURT, DEAD }
enum Facing { DOWN, UP, LEFT, RIGHT }

var health: float
var _state: State = State.IDLE
var _facing: Facing = Facing.DOWN
var _state_timer: float = 0.0
var _invincible: bool = false
var _last_anim: String = ""

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _hurtbox: Area2D = $HurtBox
@onready var _hitbox: Area2D = $HitBox

func _ready() -> void:
	health = max_health
	_play_current_animation()

func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	velocity = input_dir * move_speed
	move_and_slide()

	if input_dir != Vector2.ZERO:
		_update_facing(input_dir)

	if _state == State.HURT or _state == State.SHOOT:
		_state_timer -= delta
		if _state_timer <= 0.0:
			_enter_state(State.WALK if input_dir != Vector2.ZERO else State.IDLE)
	elif _state == State.IDLE and input_dir != Vector2.ZERO:
		_enter_state(State.WALK)
	elif _state == State.WALK and input_dir == Vector2.ZERO:
		_enter_state(State.IDLE)

	_resolve_hurtbox()
	_resolve_hitbox()

# --- Public API --------------------------------------------------------------

func take_damage(amount: float, _source_position: Vector2 = Vector2.ZERO) -> void:
	if _invincible or _state == State.DEAD:
		return
	health -= amount
	if health <= 0.0:
		_die()
		return
	_enter_state(State.HURT)
	_start_invincibility()

func shoot(aim_direction: Vector2 = Vector2.ZERO) -> void:
	if _state == State.DEAD or _state == State.HURT:
		return
	if aim_direction != Vector2.ZERO:
		_update_facing(aim_direction)
	_enter_state(State.SHOOT)

# --- Internals ---------------------------------------------------------------

func _die() -> void:
	_enter_state(State.DEAD)
	health_depleted.emit()

func _update_facing(dir: Vector2) -> void:
	var old := _facing
	if absf(dir.x) > absf(dir.y):
		_facing = Facing.LEFT if dir.x < 0.0 else Facing.RIGHT
	else:
		_facing = Facing.UP if dir.y < 0.0 else Facing.DOWN
	if _facing != old:
		_play_current_animation()

func _enter_state(new_state: State) -> void:
	if new_state == _state:
		return
	_state = new_state
	match new_state:
		State.HURT: _state_timer = hurt_time
		State.SHOOT: _state_timer = shoot_time
		_: _state_timer = 0.0
	_play_current_animation()

# Continuous contact damage: any enemy inside HurtBox hits us, then i-frames.
func _resolve_hurtbox() -> void:
	if _invincible:
		return
	var bodies := _hurtbox.get_overlapping_bodies()
	if bodies.is_empty():
		return
	take_damage(contact_damage_taken, (bodies[0] as Node2D).global_position)

# Continuous melee: any enemy inside HitBox takes damage + knockback.
func _resolve_hitbox() -> void:
	for body in _hitbox.get_overlapping_bodies():
		if body.has_method("take_damage"):
			var push_dir := (body.global_position - global_position).normalized()
			body.take_damage(push_dir, melee_knockback)

func _start_invincibility() -> void:
	_invincible = true
	get_tree().create_timer(invincibility_time).timeout.connect(
		func(): _invincible = false
	)

func _play_current_animation() -> void:
	if _sprite == null or _sprite.sprite_frames == null:
		return
	var anim := _current_anim_name()
	if anim == _last_anim:
		return
	if _sprite.sprite_frames.has_animation(anim):
		_last_anim = anim
		_sprite.play(anim)
	elif _sprite.sprite_frames.has_animation("default") and _last_anim != "default":
		_last_anim = "default"
		_sprite.play("default")

func _current_anim_name() -> String:
	var base := ""
	match _state:
		State.IDLE: base = "idle"
		State.WALK: base = "walk"
		State.SHOOT: base = "shoot"
		State.HURT: base = "hurt"
		State.DEAD: base = "death"
	var suffix := ""
	match _facing:
		Facing.DOWN: suffix = "down"
		Facing.UP: suffix = "up"
		Facing.LEFT: suffix = "left"
		Facing.RIGHT: suffix = "right"
	return "%s_%s" % [base, suffix]
