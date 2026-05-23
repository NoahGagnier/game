class_name HeartPickup
extends Pickup

@export var heal_amount: float = 50.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	super._ready()
	_sprite.play("default")

func apply(player: Player) -> void:
	player.heal(heal_amount)
