class_name Player
extends CharacterBody2D

signal health_depleted
signal health_changed(current: float, max_health: float)

@export var max_health: float = 100.0
@export var move_speed: float = 225.0
@export var invincibility_time: float = 0.5
@export var hurt_time: float = 0.25
@export var attack_time: float = 0.25
@export var attack_offset: float = 40.0
@export var physical_damage: float = 30.0
@export var attack_damage_knockback: float = 500.0
@export var contact_damage_taken: float = 20.0

enum State { IDLE, WALK, ATTACK, HURT, DEAD }
enum Facing { DOWN, UP, LEFT, RIGHT }

var health: float
var regen_rate: float = 0.0
var crit_chance: float = 0.0
var crit_multiplier: float = 3.0
var dodge_chance: float = 0.0
var thorn_knockback: float = 0.0
var heal_on_hit: float = 0.0
var holy_damage: float = 20.0
var _weapon: Weapon
var _state: State = State.IDLE
var _facing: Facing = Facing.DOWN
var _state_timer: float = 0.0
var _invincible: bool = false
var _last_anim: String = ""
var _hit_targets: Array[Node] = []

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _hurtbox: Area2D = $HurtBox
@onready var _hitbox: Area2D = $HitBox

func _ready() -> void:
	add_to_group("player")
	_set_health(max_health)
	_hitbox.monitoring = false
	_play_current_animation()

func _set_health(new_health: float) -> void:
	health = clampf(new_health, 0.0, max_health)
	health_changed.emit(health, max_health)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("weapon_fire"):
		try_fire_weapon()
	if event.is_action_pressed("attack"):
		attack()

func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		velocity = Vector2.ZERO
		move_and_slide()
		return

	if regen_rate > 0.0 and health < max_health:
		_set_health(health + regen_rate * delta)

	var input_dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")

	velocity = input_dir * move_speed
	move_and_slide()

	if input_dir != Vector2.ZERO:
		_update_facing(input_dir)

	if _state == State.HURT or _state == State.ATTACK:
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

func take_damage(amount: float, _source_position: Vector2 = Vector2.ZERO) -> bool:
	if _invincible or _state == State.DEAD:
		return false
	if dodge_chance > 0.0 and randf() < dodge_chance:
		_start_invincibility()
		var shield := get_node_or_null("HolyAmpuleShield")
		if shield != null and shield.has_method("flash"):
			shield.flash()
		return false
	_set_health(health - amount)
	if health <= 0.0:
		_die()
		return true
	_enter_state(State.HURT)
	_start_invincibility()
	return true

func attack(aim_direction: Vector2 = Vector2.ZERO) -> void:
	if _state == State.DEAD or _state == State.HURT or _state == State.ATTACK:
		return
	if aim_direction != Vector2.ZERO:
		_update_facing(aim_direction)
	_enter_state(State.ATTACK)

func heal(amount: float) -> void:
	if _state == State.DEAD or amount <= 0.0:
		return
	_set_health(health + amount)

# Permanently raises max_health by `amount` and tops the player off by the same
# amount, so the freshly added chunk of the bar starts full.
func increase_max_health(amount: float) -> void:
	if _state == State.DEAD or amount <= 0.0:
		return
	max_health += amount
	_set_health(health + amount)

func equip_weapon(weapon: Weapon) -> void:
	if _weapon != null:
		_weapon.queue_free()
	_weapon = weapon
	add_child(_weapon)
	_weapon.bind_player(self)

func try_fire_weapon() -> void:
	if _weapon != null:
		_weapon.try_fire()

func get_facing_vector() -> Vector2:
	return _facing_vector()

# Rolls crit, applies damage, and triggers on-hit heal for any player attack.
func deal_damage_to(
	target: Node2D,
	hit_direction: Vector2,
	base_amount: float,
	base_knockback: float,
	kind: DamageKind.Type,
) -> void:
	if not target.has_method("take_damage"):
		return
	var amount := base_amount
	var knockback := base_knockback
	if crit_chance > 0.0 and randf() < crit_chance:
		amount *= crit_multiplier
		knockback *= crit_multiplier
	target.take_damage(hit_direction, amount, knockback, kind)
	if heal_on_hit > 0.0:
		heal(heal_on_hit)

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

func _facing_vector() -> Vector2:
	match _facing:
		Facing.UP: return Vector2.UP
		Facing.LEFT: return Vector2.LEFT
		Facing.RIGHT: return Vector2.RIGHT
		_: return Vector2.DOWN

func _enter_state(new_state: State) -> void:
	if new_state == _state:
		return

	# Leaving ATTACK: stop swinging.
	if _state == State.ATTACK:
		_hitbox.monitoring = false
		_hit_targets.clear()

	_state = new_state

	match new_state:
		State.HURT:
			_state_timer = hurt_time
		State.ATTACK:
			_state_timer = attack_time
			_hitbox.position = _facing_vector() * attack_offset
			_hitbox.monitoring = true
			_hit_targets.clear()
		_:
			_state_timer = 0.0

	_play_current_animation()

# Enemy inside our HurtBox hits us once, then i-frames give us breathing room.
func _resolve_hurtbox() -> void:
	if _invincible:
		return
	var bodies := _hurtbox.get_overlapping_bodies()
	if bodies.is_empty():
		return
	var attacker := bodies[0] as Node2D
	var hit_landed := take_damage(contact_damage_taken, attacker.global_position)
	if hit_landed and thorn_knockback > 0.0 and attacker.has_method("take_damage"):
		var push_dir := (attacker.global_position - global_position).normalized()
		attacker.take_damage(push_dir, 15.0, thorn_knockback, DamageKind.Type.PHYSICAL)

# Only hurts enemies while we're actively swinging, and only hits each enemy
# once per swing so a long overlap doesn't drain their HP instantly.
func _resolve_hitbox() -> void:
	if _state != State.ATTACK:
		return
	for body in _hitbox.get_overlapping_bodies():
		if body in _hit_targets:
			continue
		_hit_targets.append(body)
		if body is Node2D:
			var push_dir := (body.global_position - global_position).normalized()
			deal_damage_to(body, push_dir, physical_damage, attack_damage_knockback, DamageKind.Type.PHYSICAL)

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
		State.ATTACK: base = "attack"
		State.HURT: base = "hurt"
		State.DEAD: base = "death"
	var suffix := ""
	match _facing:
		Facing.DOWN: suffix = "down"
		Facing.UP: suffix = "up"
		Facing.LEFT: suffix = "left"
		Facing.RIGHT: suffix = "right"
	return "%s_%s" % [base, suffix]
