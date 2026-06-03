extends CanvasLayer

const FILL_COLOR := Color(0.87, 0.23, 0.26, 1.0)
const FLASH_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const FLASH_DURATION := 0.25

@export var player_path: NodePath = ^"../World/Player"

var _fill_style: StyleBoxFlat
var _flash_tween: Tween
var _boss_connected: bool = false

@onready var _bar: TextureProgressBar = $ProgressBar
@onready var _label: Label = $Label
@onready var _item_popup: ItemPopup = $ItemPopup
@onready var _boss_bar: Control = $BossBar

func _ready() -> void:
	ItemEvents.item_collected.connect(_item_popup.show_item)

	var player := get_node_or_null(player_path) as Player
	if player == null:
		push_warning("HUD: could not find Player at %s" % player_path)
		return
	player.health_changed.connect(_on_player_health_changed)
	_on_player_health_changed(player.health, player.max_health)

## Called by game.gd when the player enters the boss room.
func show_boss_bar() -> void:
	if _boss_connected:
		return
	var boss := get_tree().get_first_node_in_group("boss")
	if boss == null or not is_instance_valid(boss):
		return
	_boss_connected = true
	var display_name: String = "BOSS"
	if "boss_name" in boss:
		display_name = boss.boss_name
	_boss_bar.bind(boss, display_name)
	boss.tree_exited.connect(func() -> void: _boss_connected = false, CONNECT_ONE_SHOT)

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
