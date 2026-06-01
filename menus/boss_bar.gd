extends Control

const FILL_COLOR       := Color(0.72, 0.06, 0.06)
const BG_COLOR         := Color(0.12, 0.02, 0.02)
const PANEL_COLOR      := Color(0.04, 0.00, 0.00, 0.88)
const FADE_DURATION    := 0.45
const DRAIN_DURATION   := 0.20

@onready var _name_label: Label        = $VBox/NameLabel
@onready var _bar: ProgressBar         = $VBox/Bar

var _fade_tween:  Tween
var _drain_tween: Tween

func _ready() -> void:
	visible   = false
	modulate.a = 0.0
	var fill_style := StyleBoxFlat.new()
	fill_style.bg_color = FILL_COLOR
	fill_style.set_corner_radius_all(3)
	_bar.add_theme_stylebox_override("fill", fill_style)

	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = BG_COLOR
	bg_style.set_corner_radius_all(3)
	_bar.add_theme_stylebox_override("background", bg_style)

func bind(boss: Node, display_name: String) -> void:
	_name_label.text = display_name
	if "max_health" in boss:
		_bar.max_value = boss.max_health
	if "health" in boss:
		_bar.value = boss.health
	if boss.has_signal("health_changed"):
		boss.health_changed.connect(_on_health_changed)
	boss.tree_exited.connect(_on_boss_removed)
	_fade_in()

func _fade_in() -> void:
	visible = true
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", 1.0, FADE_DURATION)

func _fade_out() -> void:
	if _fade_tween != null and _fade_tween.is_valid():
		_fade_tween.kill()
	_fade_tween = create_tween()
	_fade_tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	_fade_tween.tween_callback(func() -> void: visible = false)

func _on_health_changed(current: float, new_max: float) -> void:
	_bar.max_value = new_max
	if _drain_tween != null and _drain_tween.is_valid():
		_drain_tween.kill()
	_drain_tween = create_tween()
	_drain_tween.tween_property(_bar, "value", current, DRAIN_DURATION)
	if current <= 0.0:
		_fade_out()

func _on_boss_removed() -> void:
	_fade_out()
