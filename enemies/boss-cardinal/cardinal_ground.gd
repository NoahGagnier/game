extends Area2D

const GROUND_TEXTURE := preload("res://enemies/boss-cardinal/assets/holy-ground-attack.png")
const FRAME_WIDTH := 64.0
const FRAME_HEIGHT := 32.0
const FRAME_COUNT := 18

# Damage is active during this frame window (inclusive).
const DAMAGE_FRAME_START := 11
const DAMAGE_FRAME_END := 16

@export var anim_speed: float = 18.0

var _damage: float = 25.0
var _hit_targets: Array[Node] = []

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_setup_animation()

func setup(target_pos: Vector2, damage: float) -> void:
	global_position = target_pos
	_damage = damage

func _process(_delta: float) -> void:
	if not is_instance_valid(_sprite):
		return
	var f := _sprite.frame
	if f >= DAMAGE_FRAME_START and f <= DAMAGE_FRAME_END:
		for body in get_overlapping_bodies():
			_on_body_entered(body)

func _setup_animation() -> void:
	const ANIM := &"default"
	var frames := SpriteFrames.new()
	if not frames.has_animation(ANIM):
		frames.add_animation(ANIM)
	frames.set_animation_loop(ANIM, false)
	frames.set_animation_speed(ANIM, anim_speed)
	for i in FRAME_COUNT:
		var atlas := AtlasTexture.new()
		atlas.atlas = GROUND_TEXTURE
		atlas.region = Rect2(i * FRAME_WIDTH, 0.0, FRAME_WIDTH, FRAME_HEIGHT)
		frames.add_frame(ANIM, atlas)
	_sprite.sprite_frames = frames
	if not _sprite.animation_finished.is_connected(queue_free):
		_sprite.animation_finished.connect(queue_free, CONNECT_ONE_SHOT)
	_sprite.play(ANIM)

func _on_body_entered(body: Node2D) -> void:
	var f := _sprite.frame if is_instance_valid(_sprite) else -1
	if f < DAMAGE_FRAME_START or f > DAMAGE_FRAME_END:
		return
	if body in _hit_targets:
		return
	if body is Player:
		_hit_targets.append(body)
		body.take_damage(_damage, global_position)
