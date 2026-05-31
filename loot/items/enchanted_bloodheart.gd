class_name EnchantedBloodheart
extends Pickup

# A rare healing pickup that restores 200 HP. Not in any chest table or
# enemy drop pool by default -- drop it manually into a scene where you
# want it to appear.

@export var heal_amount: float = 200.0

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D

func _ready() -> void:
	super._ready()
	_sprite.play("default")

func apply(player: Player) -> void:
	player.heal(heal_amount)
