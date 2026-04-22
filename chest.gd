class_name Chest
extends StaticBody2D

signal opened(chest: Chest)

@export var contents: Array[PackedScene] = []
@export var content_spawn_spread: float = 16.0

var is_open: bool = false
var _player_in_range: bool = false

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var _prompt: Label = $InteractPrompt

func _ready() -> void:
	_prompt.visible = false
	_play_animation("closed")

func _unhandled_input(event: InputEvent) -> void:
	if is_open or not _player_in_range:
		return
	if event.is_action_pressed("interact"):
		open()

func open() -> void:
	if is_open:
		return
	is_open = true
	_player_in_range = false
	_prompt.visible = false
	_play_animation("open")
	_spawn_contents()
	opened.emit(self)

func _spawn_contents() -> void:
	var parent := get_parent()
	if parent == null:
		return
	var count := contents.size()
	for i in range(count):
		var scene := contents[i]
		if scene == null:
			continue
		var item := scene.instantiate() as Node2D
		if item == null:
			continue
		parent.add_child(item)
		# Fan the items out so they don't stack on top of each other.
		var angle := TAU * float(i) / float(max(count, 1))
		var offset := Vector2.RIGHT.rotated(angle) * content_spawn_spread
		item.global_position = global_position + offset

func _play_animation(anim: String) -> void:
	if _sprite.sprite_frames == null:
		return
	if _sprite.sprite_frames.has_animation(anim):
		_sprite.play(anim)
	elif _sprite.sprite_frames.has_animation("default"):
		_sprite.play("default")

func _on_interact_area_body_entered(body: Node2D) -> void:
	if is_open:
		return
	if body is Player:
		_player_in_range = true
		_prompt.visible = true

func _on_interact_area_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_in_range = false
		_prompt.visible = false
