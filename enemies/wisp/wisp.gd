class_name Wisp
extends CharacterBody2D

const EnemyVision = preload("res://enemies/enemy_vision.gd")

@export var max_health: float = 50.0
@export var move_speed: float = 76.0
@export var knockback_decay: float = 600.0
@export var room_margin: float = 24.0
@export var hover_amplitude: float = 6.0
@export var hover_speed: float = 0.9
@export var shadow_ground_y: float = 12.0
@export var shadow_base_scale: Vector2 = Vector2(0.95, 0.32)
@export var shadow_color: Color = Color(0.0, 0.0, 0.0, 0.38)
@export_group("Animations")
@export var float_texture: Texture2D = preload("res://enemies/wisp/assets/wisp.png")
@export var frame_count: int = 19
@export var frame_size: Vector2 = Vector2(32.0, 32.0)
@export var anim_speed: float = 10.0
## Drop your death sheet in enemies/wisp/assets/ and assign it here.
@export var death_texture: Texture2D
@export var death_frame_count: int = 1
@export var death_frame_size: Vector2 = Vector2(32.0, 32.0)
@export var death_anim_speed: float = 8.0
@export var anim_death: String = "death"
@export var death_linger_duration: float = 0.0

@export_group("Drops")
@export var drop_scene: PackedScene
@export_range(0.0, 1.0) var drop_chance: float = 0.08
@export var drop_spread: float = 24.0
## Independent bonus drop (e.g. Key). Rolled separately from the main drop.
@export var bonus_drop_scene: PackedScene
@export_range(0.0, 1.0) var bonus_drop_chance: float = 0.0

var health: float
var _dead: bool = false
var _knockback: Vector2 = Vector2.ZERO
var _hover_time: float = 0.0
var _player: Node2D
var _room: Room

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _shadow: AnimatedSprite2D = $Shadow

func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	_setup_animation()
	_shadow.z_index = -1
	_shadow.modulate = shadow_color
	_shadow.position.y = shadow_ground_y
	_refresh_player()
	_room = _find_owning_room()

func _physics_process(delta: float) -> void:
	if _dead:
		return

	if not is_instance_valid(_player):
		_refresh_player()

	_knockback = _knockback.move_toward(Vector2.ZERO, knockback_decay * delta)
	_update_hover(delta)

	var move := Vector2.ZERO
	if _can_target_player():
		move = global_position.direction_to(_player.global_position) * move_speed

	velocity = move + _knockback
	move_and_slide()
	_confine_to_room()

func take_damage(
	hit_direction: Vector2 = Vector2.ZERO,
	amount: float = 30.0,
	knockback: float = 500.0,
	_kind: DamageKind.Type = DamageKind.Type.PHYSICAL,
) -> void:
	if health <= 0.0:
		return
	health -= amount
	if hit_direction != Vector2.ZERO:
		_knockback += hit_direction.normalized() * knockback
	if health <= 0.0:
		_die()
		return
	_sprite.modulate = Color(1.6, 0.35, 0.35, 1.0)
	await get_tree().create_timer(0.12).timeout
	if is_instance_valid(_sprite) and not _dead:
		_sprite.modulate = Color.WHITE

func _setup_animation() -> void:
	if float_texture == null:
		return
	var frames := SpriteFrames.new()
	_add_sheet_frames(frames, "float", float_texture, frame_count, frame_size, anim_speed, true)
	if death_texture != null:
		_add_sheet_frames(
			frames,
			anim_death,
			death_texture,
			death_frame_count,
			death_frame_size,
			death_anim_speed,
			false,
		)
	_sprite.sprite_frames = frames
	_shadow.sprite_frames = frames
	_sprite.play("float")
	_shadow.play("float")

func _add_sheet_frames(
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

func _update_hover(delta: float) -> void:
	_hover_time += delta
	var hover_y := sin(_hover_time * TAU * hover_speed) * hover_amplitude
	_sprite.position.y = hover_y
	_shadow.frame = _sprite.frame

	var lift := clampf((hover_y + hover_amplitude) / (hover_amplitude * 2.0), 0.0, 1.0)
	_shadow.scale = Vector2(
		lerpf(shadow_base_scale.x, shadow_base_scale.x * 0.68, lift),
		lerpf(shadow_base_scale.y, shadow_base_scale.y * 0.55, lift),
	)
	var shadow_alpha := lerpf(shadow_color.a, shadow_color.a * 0.35, lift)
	_shadow.modulate = Color(shadow_color.r, shadow_color.g, shadow_color.b, shadow_alpha)

func _die() -> void:
	_dead = true
	velocity = Vector2.ZERO
	_knockback = Vector2.ZERO
	remove_from_group("enemies")
	for child in get_children():
		if child is CollisionShape2D:
			(child as CollisionShape2D).set_deferred("disabled", true)
	_try_drop_loot()
	_shadow.visible = false

	if death_texture != null and _sprite.sprite_frames != null and _sprite.sprite_frames.has_animation(anim_death):
		_sprite.modulate = Color.WHITE
		_sprite.position.y = 0.0
		_sprite.play(anim_death)
		if not _sprite.animation_finished.is_connected(_on_death_anim_finished):
			_sprite.animation_finished.connect(_on_death_anim_finished, CONNECT_ONE_SHOT)
		return

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_sprite, "modulate:a", 0.0, 0.35)
	await tween.finished
	queue_free()

func _on_death_anim_finished() -> void:
	if _sprite.animation != anim_death:
		return
	_sprite.pause()
	if death_linger_duration > 0.0:
		await get_tree().create_timer(death_linger_duration).timeout
	queue_free()

func _refresh_player() -> void:
	_player = get_tree().get_first_node_in_group("player") as Node2D
	if _player is PhysicsBody2D:
		add_collision_exception_with(_player)

func _can_target_player() -> bool:
	return EnemyVision.can_target_player(
		self,
		_player,
		_room,
		-1.0,
		EnemyVision.VisionMode.PERIMETER_WALLS_ONLY,
	)

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
