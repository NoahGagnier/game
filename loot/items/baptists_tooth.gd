class_name BaptistsTooth
extends Pickup

# Each tooth collected stacks +10% crit chance.
@export var crit_chance_bonus: float = 0.10
@export var animation_fps: float = 6.0

@onready var _sprite: Sprite2D = $Sprite2D

var _anim_time: float = 0.0

func _ready() -> void:
	super._ready()

func _process(delta: float) -> void:
	super._process(delta)
	_anim_time += delta
	_sprite.frame = int(_anim_time * animation_fps) % 2

func apply(player: Player) -> void:
	player.crit_chance += crit_chance_bonus
