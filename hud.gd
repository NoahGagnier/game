extends CanvasLayer

const FILL_COLOR := Color(0.87, 0.23, 0.26, 1.0)
const FLASH_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const FLASH_DURATION := 0.25

@export var player_path: NodePath = ^"../Player"

var _fill_style: StyleBoxFlat
var _flash_tween: Tween

@onready var _bar: TextureProgressBar = $ProgressBar
@onready var _label: Label = $Label
@onready var _item_popup: ItemPopup = $ItemPopup

func _ready() -> void:
	ItemEvents.item_collected.connect(_item_popup.show_item)

	var player := get_node_or_null(player_path) as Player
	if player == null:
		push_warning("HUD: could not find Player at %s" % player_path)
		return
	player.health_changed.connect(_on_player_health_changed)
	_on_player_health_changed(player.health, player.max_health)

func _on_player_health_changed(current: float, max_health: float) -> void:
	var previous := _bar.value
	_bar.max_value = max_health
	_bar.value = current
	_label.text = "%d / %d" % [int(ceilf(current)), int(max_health)]
	if current < previous:
		_flash_damage()

func _flash_damage() -> void:
	if _flash_tween != null and _flash_tween.is_valid():
		_flash_tween.kill()
	_bar.modulate = FLASH_COLOR
	_flash_tween = create_tween()
	_flash_tween.tween_property(_bar, "modulate", Color.WHITE, FLASH_DURATION)
