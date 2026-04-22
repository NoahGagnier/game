extends CanvasLayer

@export var player_path: NodePath = ^"../Player"

@onready var _bar: ProgressBar = $VBoxContainer/ProgressBar
@onready var _label: Label = $VBoxContainer/Label

func _ready() -> void:
	var player := get_node_or_null(player_path) as Player
	if player == null:
		push_warning("HUD: could not find Player at %s" % player_path)
		return
	player.health_changed.connect(_on_player_health_changed)
	_on_player_health_changed(player.health, player.max_health)

func _on_player_health_changed(current: float, max_health: float) -> void:
	_bar.max_value = max_health
	_bar.value = current
	_label.text = "%d / %d" % [int(ceilf(current)), int(max_health)]
