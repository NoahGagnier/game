extends Area2D

const BEAM_TEXTURE := preload("res://enemies/holy-beam-attack.png")
const FRAME_WIDTH := 10.0
const FRAME_HEIGHT := 128.0
const FRAME_COUNT := 13

# 2x the Blood of Januarius beam (256 → 512 length, 20 → 40 width)
const BEAM_LENGTH := 512.0
const BEAM_WIDTH := 40.0

# Damage only fires on these frames — the final "release" phase.
const DAMAGE_FRAME_START := 11

@export var anim_speed: float = 20.0

var _damage: float = 18.0
var _hit_targets: Array[Node] = []

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_setup_animation()

func setup(origin: Vector2, direction: Vector2, damage: float) -> void:
	global_position = origin
	rotation = direction.normalized().angle()
	_damage = damage

# Each frame, if we're in the damage window, check for any bodies already
# overlapping (catches the player who was standing in the beam path).
func _process(_delta: float) -> void:
	if not is_instance_valid(_sprite):
		return
	if _sprite.frame >= DAMAGE_FRAME_START:
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
		atlas.atlas = BEAM_TEXTURE
		atlas.region = Rect2(i * FRAME_WIDTH, 0.0, FRAME_WIDTH, FRAME_HEIGHT)
		frames.add_frame(ANIM, atlas)
	_sprite.sprite_frames = frames
	if not _sprite.animation_finished.is_connected(queue_free):
		_sprite.animation_finished.connect(queue_free, CONNECT_ONE_SHOT)
	_sprite.play(ANIM)

func _on_body_entered(body: Node2D) -> void:
	# Ignore hits outside the damage window.
	if not is_instance_valid(_sprite) or _sprite.frame < DAMAGE_FRAME_START:
		return
	if body in _hit_targets:
		return
	if body is Player:
		_hit_targets.append(body)
		body.take_damage(_damage, global_position)
