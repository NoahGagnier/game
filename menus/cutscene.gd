extends Control

const GAME_SCENE := "res://game.tscn"

@export var slides: Array[CutsceneSlide] = []
@export var chars_per_second: float = 30.0
@export var fade_duration: float = 0.5

@onready var _static_display: TextureRect = $StaticDisplay
@onready var _anim_display: Sprite2D = $AnimatedDisplay
@onready var _label: RichTextLabel = $TextBox/Label
@onready var _fade: ColorRect = $Fade

var _slide_index: int = 0
var _char_index: float = 0.0
var _slide_timer: float = 0.0
var _anim_frame: float = 0.0
var _finished: bool = false
var _fading: bool = false

func _ready() -> void:
	_fading = true
	_fade.modulate.a = 1.0
	_label.text = ""
	_label.visible_characters = 0
	_static_display.visible = false
	_anim_display.visible = false

	if slides.is_empty():
		_finish()
		return

	await _fade_to(0.0)
	_show_slide(_slide_index)
	_fading = false

func _process(delta: float) -> void:
	if _finished or _fading:
		return

	var slide := slides[_slide_index]

	# Typewriter.
	if not slide.text.is_empty():
		_char_index += chars_per_second * delta
		_label.visible_characters = mini(int(_char_index), slide.text.length())

	# Manual frame advance for animated slides.
	if slide.is_animated and slide.frame_count > 1:
		_anim_frame += slide.fps * delta
		_anim_display.frame = int(_anim_frame) % slide.frame_count

	# Slide timer.
	_slide_timer -= delta
	if _slide_timer <= 0.0:
		_fading = true
		_next_slide()

func _show_slide(index: int) -> void:
	var slide := slides[index]
	_char_index = 0.0
	_anim_frame = 0.0
	_slide_timer = slide.duration
	_label.text = slide.text
	_label.visible_characters = 0

	if slide.is_animated and slide.texture != null:
		_static_display.visible = false
		_anim_display.visible = true
		_anim_display.texture = slide.texture
		var fc := maxi(slide.frame_count, 1)
		_anim_display.hframes = fc
		_anim_display.vframes = 1
		_anim_display.frame = 0
		# Scale to fill screen.
		var frame_w := slide.texture.get_width() / float(fc)
		var frame_h := float(slide.texture.get_height())
		var vp := get_viewport_rect().size
		var s := minf(vp.x / frame_w, vp.y / frame_h)
		_anim_display.scale = Vector2(s, s)
		_anim_display.position = vp / 2.0
	else:
		_anim_display.visible = false
		_static_display.visible = true
		_static_display.texture = slide.texture

func _next_slide() -> void:
	var prev_slide := slides[_slide_index]
	_slide_index += 1
	if _slide_index >= slides.size():
		_finish()
		return
	if prev_slide.fade_out:
		await _fade_to(1.0)
	_show_slide(_slide_index)
	if prev_slide.fade_out:
		await _fade_to(0.0)
	_fading = false

func _fade_to(target_alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", target_alpha, fade_duration)
	await tween.finished

func _finish() -> void:
	if _finished:
		return
	_finished = true
	await _fade_to(1.0)
	await _on_cutscene_complete()

func _on_cutscene_complete() -> void:
	get_tree().change_scene_to_file(GAME_SCENE)
