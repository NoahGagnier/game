class_name Rat
extends CharacterBody2D

# A small, twitchy enemy. Wanders randomly when the player is out of range.
# When the player comes close, it dashes in short bursts toward them, bites
# on contact, then retreats before darting in again.

@export var max_health: float = 90.0

@export_group("Movement")
@export var wander_speed: float = 55.0
@export var dash_speed: float = 160.0
@export var retreat_speed: float = 200.0
@export var knockback_decay: float = 900.0

@export_group("Behavior")
@export var aggro_radius: float = 220.0
@export var room_margin: float = 24.0
@export var attack_range: float = 24.0
@export var dash_duration: float = 0.35
@export var pause_duration_min: float = 1.0
@export var pause_duration_max: float = 1.7
@export var bite_duration: float = 0.30
@export var retreat_duration: float = 0.55
@export var wander_change_min: float = 1.2
@export var wander_change_max: float = 2.8

@export_group("Animations")
@export var anim_run_down: String = "run_down"
@export var anim_run_up: String = "run_up"
@export var anim_run_left: String = "run_left"
@export var anim_run_right: String = "run_right"
@export var anim_hurt_down: String = "hurt_down"
@export var anim_hurt_up: String = "hurt_up"
@export var anim_hurt_left: String = "hurt_left"
@export var anim_hurt_right: String = "hurt_right"
@export var anim_idle_left: String = "idle_left"
@export var anim_idle_right: String = "idle_right"
@export var anim_idle_hurt: String = "idle_hurt"
@export var anim_death: String = "death"
@export var hurt_anim_duration: float = 0.3
@export var death_linger_duration: float = 15.0

@export_group("Drops")
@export var drop_scene: PackedScene
@export_range(0.0, 1.0) var drop_chance: float = 0.08
@export var drop_spread: float = 24.0

enum State { WANDER, PAUSE, DASH, BITE, RETREAT, DEAD }
enum Facing { DOWN, UP, LEFT, RIGHT }

var health: float
var _state: State = State.WANDER
var _state_timer: float = 0.0
var _wander_dir: Vector2 = Vector2.ZERO
var _dash_dir: Vector2 = Vector2.ZERO
var _knockback: Vector2 = Vector2.ZERO
var _facing: Facing = Facing.DOWN
var _last_horizontal_facing: Facing = Facing.RIGHT
var _hurt_timer: float = 0.0
var _player: Node2D
var _room: Room

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	_refresh_player()
	_room = _find_owning_room()
	_enter_wander()

func _physics_process(delta: float) -> void:
	if _state == State.DEAD:
		return

	if not is_instance_valid(_player):
		_refresh_player()

	_state_timer -= delta
	_hurt_timer = maxf(0.0, _hurt_timer - delta)
	_knockback = _knockback.move_toward(Vector2.ZERO, knockback_decay * delta)

	var move := Vector2.ZERO
	match _state:
		State.WANDER:
			move = _wander_dir * wander_speed
			if _state_timer <= 0.0:
				_pick_wander_dir()
			if _player_in_aggro():
				_enter_dash()
		State.PAUSE:
			if _state_timer <= 0.0:
				if _player_in_aggro():
					if _distance_to_player() <= attack_range:
						_enter_bite()
					else:
						_enter_dash()
				else:
					_enter_wander()
		State.DASH:
			move = _dash_dir * dash_speed
			# Bite the instant we get within range, so we don't overshoot
			# through the player (who has no collision layer).
			if _distance_to_player() <= attack_range:
				_enter_bite()
			elif _state_timer <= 0.0:
				_enter_pause()
		State.BITE:
			if _state_timer <= 0.0:
				_enter_retreat()
		State.RETREAT:
			if is_instance_valid(_player):
				move = (global_position - _player.global_position).normalized() * retreat_speed
			if _state_timer <= 0.0:
				_enter_pause()

	velocity = move + _knockback
	move_and_slide()
	_confine_to_room()
	_update_facing(move)
	_update_animation(move)

func take_damage(
	hit_direction: Vector2 = Vector2.ZERO,
	amount: float = 30.0,
	knockback: float = 500.0,
	_kind: DamageKind.Type = DamageKind.Type.PHYSICAL,
) -> void:
	if _state == State.DEAD:
		return
	health -= amount
	if hit_direction != Vector2.ZERO:
		_knockback += hit_direction.normalized() * knockback
	_hurt_timer = hurt_anim_duration
	if health <= 0.0:
		_enter_dead()

func _enter_dead() -> void:
	_state = State.DEAD
	velocity = Vector2.ZERO
	_knockback = Vector2.ZERO
	remove_from_group("enemies")
	# Disable collision so we stop bumping into / damaging the player.
	for child in get_children():
		if child is CollisionShape2D:
			(child as CollisionShape2D).set_deferred("disabled", true)

	_try_drop_loot()

	if _sprite.sprite_frames != null and _sprite.sprite_frames.has_animation(anim_death):
		_sprite.flip_h = (_last_horizontal_facing == Facing.LEFT)
		_sprite.play(anim_death)
		if not _sprite.animation_finished.is_connected(_on_death_anim_finished):
			_sprite.animation_finished.connect(_on_death_anim_finished, CONNECT_ONE_SHOT)
	else:
		# No death anim defined; just linger then disappear.
		await get_tree().create_timer(death_linger_duration).timeout
		queue_free()

func _on_death_anim_finished() -> void:
	_sprite.pause()
	await get_tree().create_timer(death_linger_duration).timeout
	queue_free()

# --- State transitions -------------------------------------------------------

func _enter_wander() -> void:
	_state = State.WANDER
	_pick_wander_dir()

func _pick_wander_dir() -> void:
	_state_timer = randf_range(wander_change_min, wander_change_max)
	_wander_dir = Vector2.from_angle(randf() * TAU)

func _enter_pause() -> void:
	_state = State.PAUSE
	_state_timer = randf_range(pause_duration_min, pause_duration_max)

func _enter_dash() -> void:
	_state = State.DASH
	_state_timer = dash_duration
	if is_instance_valid(_player):
		_dash_dir = (_player.global_position - global_position).normalized()
	else:
		_dash_dir = Vector2.ZERO

func _enter_bite() -> void:
	_state = State.BITE
	_state_timer = bite_duration

func _enter_retreat() -> void:
	_state = State.RETREAT
	_state_timer = retreat_duration

# --- Helpers -----------------------------------------------------------------

func _refresh_player() -> void:
	_player = get_tree().get_first_node_in_group("player") as Node2D
	# Physically ignore the player so the rat can't ride on top of them.
	# The player's HurtBox still detects us by collision layer.
	if _player is PhysicsBody2D:
		add_collision_exception_with(_player)

func _player_in_aggro() -> bool:
	if not is_instance_valid(_player):
		return false
	# Only chase players who are inside the same room.
	if _room != null:
		var room_rect := Rect2(_room.global_position, Vector2(Room.ROOM_SIZE, Room.ROOM_SIZE))
		if not room_rect.has_point(_player.global_position):
			return false
	return global_position.distance_to(_player.global_position) <= aggro_radius

func _find_owning_room() -> Room:
	var node: Node = get_parent()
	while node != null:
		if node is Room:
			return node
		node = node.get_parent()
	return null

func _confine_to_room() -> void:
	if _room == null:
		return
	var min_pos := _room.global_position + Vector2(room_margin, room_margin)
	var max_pos := _room.global_position + Vector2(Room.ROOM_SIZE - room_margin, Room.ROOM_SIZE - room_margin)
	global_position = global_position.clamp(min_pos, max_pos)

func _try_drop_loot() -> void:
	if drop_scene == null or randf() >= drop_chance:
		return
	var parent := get_parent()
	if parent == null:
		return
	var item := drop_scene.instantiate() as Node2D
	if item == null:
		return
	parent.add_child(item)
	item.global_position = global_position
	var angle := randf() * TAU
	var target := global_position + Vector2.RIGHT.rotated(angle) * drop_spread
	if item.has_method("pop_to"):
		item.pop_to(target)
	else:
		item.global_position = target

func _distance_to_player() -> float:
	if not is_instance_valid(_player):
		return INF
	return global_position.distance_to(_player.global_position)

func _update_facing(move: Vector2) -> void:
	if move.length() < 1.0:
		return
	if absf(move.x) > absf(move.y):
		_facing = Facing.LEFT if move.x < 0.0 else Facing.RIGHT
		_last_horizontal_facing = _facing
	else:
		_facing = Facing.UP if move.y < 0.0 else Facing.DOWN

func _update_animation(move: Vector2) -> void:
	if _sprite.sprite_frames == null:
		return

	var stationary := move.length() < 1.0

	# Hurt + stationary -> idle_hurt animation, flipped to match last facing.
	if _hurt_timer > 0.0 and stationary and _sprite.sprite_frames.has_animation(anim_idle_hurt):
		_sprite.flip_h = (_last_horizontal_facing == Facing.LEFT)
		_play(anim_idle_hurt)
		return

	# Hurt + moving -> directional hurt run animation.
	if _hurt_timer > 0.0:
		_play_directional(_hurt_anim_for_facing(), anim_hurt_left, anim_hurt_right)
		return

	# Stationary + not hurt -> idle (left/right, flipped if needed).
	if stationary:
		_play_idle()
		return

	# Moving -> directional run.
	_play_directional(_run_anim_for_facing(), anim_run_left, anim_run_right)

func _play_idle() -> void:
	var anim := anim_idle_right
	var flip := false
	if _last_horizontal_facing == Facing.LEFT:
		if _sprite.sprite_frames.has_animation(anim_idle_left):
			anim = anim_idle_left
		else:
			flip = true
	_sprite.flip_h = flip
	_play(anim)

# Plays the directional animation, falling back to a horizontally flipped
# version of the right-facing anim when the left-facing one is missing.
func _play_directional(anim: String, left_anim: String, right_anim: String) -> void:
	var flip := false
	if _facing == Facing.LEFT and not _sprite.sprite_frames.has_animation(left_anim):
		anim = right_anim
		flip = true
	_sprite.flip_h = flip
	_play(anim)

func _run_anim_for_facing() -> String:
	match _facing:
		Facing.UP: return anim_run_up
		Facing.LEFT: return anim_run_left
		Facing.RIGHT: return anim_run_right
		_: return anim_run_down

func _hurt_anim_for_facing() -> String:
	match _facing:
		Facing.UP: return anim_hurt_up
		Facing.LEFT: return anim_hurt_left
		Facing.RIGHT: return anim_hurt_right
		_: return anim_hurt_down

func _play(anim: String) -> void:
	if not _sprite.sprite_frames.has_animation(anim):
		return
	if _sprite.animation != anim or not _sprite.is_playing():
		_sprite.play(anim)
