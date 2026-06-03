@tool
extends Control

const FADE_DURATION := 0.45
const DRAIN_DURATION := 0.20

@export_group("Bar textures")
@export var bar_texture_under: Texture2D = preload(
	"res://enemies/boss-cardinal/assets/new-bosshealt..png"
)
@export var bar_texture_progress: Texture2D = preload(
	"res://enemies/boss-cardinal/assets/new-bosshealth-progression.png"
)
@export var progress_offset: Vector2 = Vector2.ZERO:
	set(value):
		progress_offset = value
		_apply_bar_textures()

@export_group("Bar size")
## Optional override. Leave at 0 to use whatever Scale is set on the Bar node in this scene.
@export_range(0.0, 8.0, 0.05) var bar_scale_override: float = 0.0:
	set(value):
		bar_scale_override = value
		_apply_bar_layout()

@onready var _name_label: Label = $NameLabel
@onready var _bar: TextureProgressBar = $Bar

var _fade_tween: Tween
var _drain_tween: Tween

func _ready() -> void:
	if Engine.is_editor_hint():
		visible = true
		modulate.a = 1.0
	else:
		visible = false
		modulate.a = 0.0
	_apply_bar_textures()
	_apply_bar_layout()

func _apply_bar_textures() -> void:
	if _bar == null:
		return
	_bar.texture_under = bar_texture_under
	_bar.texture_progress = bar_texture_progress
	_apply_progress_offset()

func _apply_bar_layout() -> void:
	if _bar == null:
		return
	if bar_scale_override > 0.0:
		_bar.scale = Vector2(bar_scale_override, bar_scale_override)
	_apply_progress_offset()

func _apply_progress_offset() -> void:
	if _bar == null:
		return
	var s := maxf(_bar.scale.x, 0.001)
	_bar.texture_progress_offset = progress_offset * s

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
