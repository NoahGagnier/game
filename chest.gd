class_name Chest
extends StaticBody2D

signal opened(chest: Chest)

@export var loot_pool: Array[LootEntry] = []
@export var drops_on_open: int = 1
@export var drop_spread: float = 28.0

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
	_drop_loot()
	opened.emit(self)

# Rolls the weighted loot_pool `drops_on_open` times (with replacement) and
# spawns each chosen item as a sibling of the chest, popped out in a small
# ring so drops don't stack on top of each other.
func _drop_loot() -> void:
	var parent := get_parent()
	if parent == null or drops_on_open <= 0:
		return

	var base_angle := randf() * TAU
	for i in range(drops_on_open):
		var entry := _pick_weighted_entry()
		if entry == null or entry.scene == null:
			continue
		var item := entry.scene.instantiate() as Node2D
		if item == null:
			continue
		parent.add_child(item)
		item.global_position = global_position
		var angle := base_angle + TAU * float(i) / float(drops_on_open)
		var target := global_position + Vector2.RIGHT.rotated(angle) * drop_spread
		if item.has_method("pop_to"):
			item.pop_to(target)
		else:
			item.global_position = target

func _pick_weighted_entry() -> LootEntry:
	var total := 0.0
	for e in loot_pool:
		if e != null and e.weight > 0.0:
			total += e.weight
	if total <= 0.0:
		return null
	var roll := randf() * total
	var acc := 0.0
	for e in loot_pool:
		if e == null or e.weight <= 0.0:
			continue
		acc += e.weight
		if roll <= acc:
			return e
	return null

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
