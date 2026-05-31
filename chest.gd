class_name Chest
extends StaticBody2D

signal opened(chest: Chest)

# A LootTable resource defines what this chest can drop. Multiple chests can
# share the same table so drop rates stay in sync. To create a new pool, copy
# loot/tables/standard_chest.tres and edit it. To add a new item, see the
# instructions at the top of loot_table.gd.
@export var loot_table: LootTable
@export var drop_spread: float = 28.0
@export var drop_delay: float = 0.7

var is_open: bool = false
var _player_in_range: bool = false

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
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
	_play_animation("open")
	if drop_delay > 0.0:
		await get_tree().create_timer(drop_delay).timeout
	_drop_loot()
	opened.emit(self)

# Asks the loot table for its rolled drops and pops each one out of the chest
# in a small ring so multiple drops don't stack on top of each other.
func _drop_loot() -> void:
	var parent := get_parent()
	if parent == null or loot_table == null:
		return

	var drops := loot_table.roll()
	if drops.is_empty():
		return

	var base_angle := randf() * TAU
	for i in range(drops.size()):
		var entry := drops[i]
		if entry == null or entry.scene == null:
			continue
		var item := entry.scene.instantiate() as Node2D
		if item == null:
			continue
		parent.add_child(item)
		item.global_position = global_position
		var angle := base_angle + TAU * float(i) / float(drops.size())
		var target := global_position + Vector2.RIGHT.rotated(angle) * drop_spread
		if item.has_method("pop_to"):
			item.pop_to(target)
		else:
			item.global_position = target

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

func _on_interact_area_body_exited(body: Node2D) -> void:
	if body is Player:
		_player_in_range = false
