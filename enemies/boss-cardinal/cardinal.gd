class_name Cardinal
extends CharacterBody2D

const EnemyVision = preload("res://enemies/enemy_vision.gd")

signal health_changed(current: float, max_health: float)

@export var boss_name: String = "THE CARDINAL"
@export var max_health: float = 550.0
@export var knockback_decay: float = 700.0
@export var room_margin: float = 24.0

@export_group("Movement")
@export var move_speed: float = 80.0
@export var preferred_distance: float = 300.0
@export var distance_tolerance: float = 40.0
@export var retreat_distance: float = 130.0

@export_group("Attack")
@export var beam_scene: PackedScene
@export var ground_scene: PackedScene
@export var beam_damage: float = 20.0
@export var ground_damage: float = 25.0
## Fire interval during a beam burst (faster than ground).
@export var beam_interval_min: float = 0.9
@export var beam_interval_max: float = 1.3
## Fire interval during a ground attack burst.
@export var ground_interval_min: float = 2.2
@export var ground_interval_max: float = 3.0
## How many attacks fire per burst before switching type.
@export var burst_min: int = 2
@export var burst_max: int = 3

@export_group("Animations")
@export var walk_texture: Texture2D
@export var walk_frame_count: int = 7
@export var walk_frame_size: Vector2 = Vector2(50.0, 80.0)
@export var walk_anim_speed: float = 8.0
@export var death_texture: Texture2D
@export var death_frame_count: int = 8
@export var death_frame_size: Vector2 = Vector2(50.0, 80.0)
@export var death_anim_speed: float = 10.0
@export var death_linger_duration: float = 15.0
@export var hurt_flash_duration: float = 0.12

@export_group("Drops")
@export var drop_scene: PackedScene
@export_range(0.0, 1.0) var drop_chance: float = 1.0
@export var drop_spread: float = 32.0
@export var bonus_drop_scene: PackedScene
@export_range(0.0, 1.0) var bonus_drop_chance: float = 0.0

enum State { APPROACH, MAINTAIN, RETREAT, DEAD }
enum AttackPhase { BEAM, GROUND }

var health: float
var _state: State = State.APPROACH
var _attack_phase: AttackPhase = AttackPhase.BEAM
var _burst_remaining: int = 0
var _knockback: Vector2 = Vector2.ZERO
var _fire_timer: float = 0.0
var _hurt_timer: float = 0.0
var _dead: bool = false
var _player: Node2D
var _room: Room

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	add_to_group("boss")
	_refresh_player()
	_room = _find_owning_room()
	_setup_animations()
	_burst_remaining = randi_range(burst_min, burst_max)
	_fire_timer = randf_range(beam_interval_min, beam_interval_max)
	health_changed.emit(health, max_health)

func _physics_process(delta: float) -> void:
	if _dead:
		return

	if not is_instance_valid(_player):
		_refresh_player()

	_knockback = _knockback.move_toward(Vector2.ZERO, knockback_decay * delta)
	_fire_timer = maxf(0.0, _fire_timer - delta)

	if _hurt_timer > 0.0:
		_hurt_timer -= delta
		if _hurt_timer <= 0.0:
			_sprite.modulate = Color.WHITE

	var can_see := _can_target_player()
	var dist := _distance_to_player()
	var move := Vector2.ZERO

	match _state:
		State.APPROACH:
			if can_see:
				if dist > preferred_distance + distance_tolerance:
					move = global_position.direction_to(_player.global_position) * move_speed
				else:
					_state = State.MAINTAIN
		State.MAINTAIN:
			if not can_see:
				_state = State.APPROACH
			elif dist < retreat_distance:
				_state = State.RETREAT
			elif dist > preferred_distance + distance_tolerance:
				_state = State.APPROACH
			else:
				_try_fire()
		State.RETREAT:
			if not can_see:
				_state = State.APPROACH
			elif dist >= preferred_distance:
				_state = State.MAINTAIN
			else:
				move = (global_position - _player.global_position).normalized() * move_speed
				_try_fire()

	velocity = move + _knockback
	move_and_slide()
	_confine_to_room()
	_update_facing()

func take_damage(
	hit_direction: Vector2 = Vector2.ZERO,
	amount: float = 30.0,
	knockback: float = 500.0,
	_kind: DamageKind.Type = DamageKind.Type.PHYSICAL,
) -> void:
	if _dead:
		return
	health -= amount
	if hit_direction != Vector2.ZERO:
		_knockback += hit_direction.normalized() * knockback
	_sprite.modulate = Color(1.6, 0.35, 0.35, 1.0)
	_hurt_timer = hurt_flash_duration
	if health <= 0.0:
		_die()
	else:
		health_changed.emit(health, max_health)

func _die() -> void:
	_dead = true
	health = 0.0
	health_changed.emit(health, max_health)
	velocity = Vector2.ZERO
	_knockback = Vector2.ZERO
	remove_from_group("enemies")
	for child in get_children():
		if child is CollisionShape2D:
			(child as CollisionShape2D).set_deferred("disabled", true)
	_try_drop_loot()
	_sprite.modulate = Color.WHITE
	if _sprite.sprite_frames != null and _sprite.sprite_frames.has_animation("death"):
		_sprite.play("death")
		_sprite.animation_finished.connect(_on_death_anim_finished, CONNECT_ONE_SHOT)
	else:
		await get_tree().create_timer(death_linger_duration).timeout
		queue_free()

func _on_death_anim_finished() -> void:
	_sprite.pause()
	await get_tree().create_timer(death_linger_duration).timeout
	queue_free()

func _try_fire() -> void:
	if _fire_timer > 0.0:
		return
	match _attack_phase:
		AttackPhase.BEAM:
			_fire_beam()
			_fire_timer = randf_range(beam_interval_min, beam_interval_max)
		AttackPhase.GROUND:
			_fire_ground()
			_fire_timer = randf_range(ground_interval_min, ground_interval_max)
	_burst_remaining -= 1
	if _burst_remaining <= 0:
		_attack_phase = AttackPhase.GROUND if _attack_phase == AttackPhase.BEAM else AttackPhase.BEAM
		_burst_remaining = randi_range(burst_min, burst_max)

func _fire_beam() -> void:
	if not is_instance_valid(_player) or beam_scene == null:
		return
	var parent := get_parent()
	if parent == null:
		return
	var beam := beam_scene.instantiate() as Node2D
	if beam == null:
		return
	parent.add_child(beam)
	var direction := global_position.direction_to(_player.global_position)
	if beam.has_method("setup"):
		beam.setup(global_position, direction, beam_damage)

func _fire_ground() -> void:
	if not is_instance_valid(_player) or ground_scene == null:
		return
	var parent := get_parent()
	if parent == null:
		return
	var attack := ground_scene.instantiate() as Node2D
	if attack == null:
		return
	parent.add_child(attack)
	if attack.has_method("setup"):
		attack.setup(_player.global_position, ground_damage)

func _update_facing() -> void:
	if not is_instance_valid(_player):
		return
	_sprite.flip_h = _player.global_position.x < global_position.x

func _can_target_player() -> bool:
	return EnemyVision.can_target_player(self, _player, _room)

func _distance_to_player() -> float:
	if not is_instance_valid(_player):
		return INF
	return global_position.distance_to(_player.global_position)

func _refresh_player() -> void:
	_player = get_tree().get_first_node_in_group("player") as Node2D
	if _player is PhysicsBody2D:
		add_collision_exception_with(_player)

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

func _setup_animations() -> void:
	if walk_texture == null:
		return
	var frames := SpriteFrames.new()
	_add_frames(frames, "walk", walk_texture, walk_frame_count, walk_frame_size, walk_anim_speed, true)
	if death_texture != null:
		_add_frames(frames, "death", death_texture, death_frame_count, death_frame_size, death_anim_speed, false)
	_sprite.sprite_frames = frames
	_sprite.play("walk")

func _add_frames(
	frames: SpriteFrames,
	anim_name: String,
	texture: Texture2D,
	count: int,
	size: Vector2,
	speed: float,
	loop: bool,
) -> void:
	frames.add_animation(anim_name)
	frames.set_animation_loop(anim_name, loop)
	frames.set_animation_speed(anim_name, speed)
	for i in count:
		var atlas := AtlasTexture.new()
		atlas.atlas = texture
		atlas.region = Rect2(i * size.x, 0.0, size.x, size.y)
		frames.add_frame(anim_name, atlas)

func _try_drop_loot() -> void:
	_roll_drop(drop_scene, drop_chance)
	_roll_drop(bonus_drop_scene, bonus_drop_chance)

func _roll_drop(scene: PackedScene, chance: float) -> void:
	if scene == null or randf() >= chance:
		return
	var parent := get_parent()
	if parent == null:
		return
	call_deferred("_spawn_drop", scene, parent, global_position, drop_spread)

func _spawn_drop(scene: PackedScene, parent: Node, origin: Vector2, spread: float) -> void:
	if scene == null or not is_instance_valid(parent):
		return
	var item := scene.instantiate() as Node2D
	if item == null:
		return
	parent.add_child(item)
	item.global_position = origin
	var angle := randf() * TAU
	var target := origin + Vector2.RIGHT.rotated(angle) * spread
	if item.has_method("pop_to"):
		item.pop_to(target)
	else:
		item.global_position = target
	if item is Pickup:
		(item as Pickup).sync_bob_origin()
