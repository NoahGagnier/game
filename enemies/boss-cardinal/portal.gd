class_name BossPortal
extends Area2D

## Emitted when the player steps in and presses Interact.
signal entered

@export_group("Animation")
@export var frame_count: int = 8
@export var frame_size: Vector2 = Vector2(32.0, 32.0)
@export var anim_speed: float = 8.0
@export var portal_texture: Texture2D = preload("res://enemies/boss-cardinal/assets/portal.png")

@export_group("Appear")
## How long the fade-in takes when the portal opens.
@export var fade_in_duration: float = 1.2

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

var _player_in_range: bool = false

func _ready() -> void:
	modulate.a = 0.0
	visible = false
	_build_frames()

func open() -> void:
	visible = true
	var tween := create_tween()
	tween.tween_property(self, "modulate:a", 1.0, fade_in_duration)

func _build_frames() -> void:
	if portal_texture == null or _sprite == null:
		return
	var frames := SpriteFrames.new()
	frames.add_animation("idle")
	frames.set_animation_loop("idle", true)
	frames.set_animation_speed("idle", anim_speed)
	for i in frame_count:
		var atlas := AtlasTexture.new()
		atlas.atlas = portal_texture
		atlas.region = Rect2(i * frame_size.x, 0.0, frame_size.x, frame_size.y)
		frames.add_frame("idle", atlas)
	_sprite.sprite_frames = frames
	_sprite.play("idle")

func _unhandled_input(event: InputEvent) -> void:
	if not visible or modulate.a < 0.9:
		return
	if not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		get_viewport().set_input_as_handled()
		get_tree().call_group("game_controller", "advance_floor")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_in_range = false
