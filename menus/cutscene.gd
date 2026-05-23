extends Control

# Slideshow cutscene. Each slide can be a static image or an animated
# spritesheet, with optional typewriter text. Slides fade in/out automatically.
#
# To set up slides, click the root Cutscene node and edit the `slides` array
# in the Inspector. Each element is a CutsceneSlide resource.

const GAME_SCENE := "res://game.tscn"

@export var slides: Array[CutsceneSlide] = []
@export var chars_per_second: float = 30.0
@export var fade_duration: float = 0.5

@onready var _static_display: TextureRect = $StaticDisplay
@onready var _anim_display: AnimatedSprite2D = $AnimatedDisplay
@onready var _label: RichTextLabel = $TextBox/Label
@onready var _fade: ColorRect = $Fade

var _slide_index: int = 0
var _char_index: float = 0.0
var _slide_timer: float = 0.0
var _finished: bool = false
var _fading: bool = false

func _ready() -> void:
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

func _process(delta: float) -> void:
	if _finished or _fading:
		return

	# Typewriter.
	var slide := slides[_slide_index]
	if not slide.text.is_empty():
		_char_index += chars_per_second * delta
		_label.visible_characters = mini(int(_char_index), slide.text.length())

	# Slide timer.
	_slide_timer -= delta
	if _slide_timer <= 0.0:
		_next_slide()

func _show_slide(index: int) -> void:
	var slide := slides[index]
	_char_index = 0.0
	_slide_timer = slide.duration
	_label.text = slide.text
	_label.visible_characters = 0

	if slide.is_animated and slide.texture != null and slide.frame_count > 1:
		_static_display.visible = false
		_anim_display.visible = true
		var frames := SpriteFrames.new()
		frames.add_animation("play")
		frames.set_animation_speed("play", slide.fps)
		frames.set_animation_loop("play", true)
		var frame_width := slide.texture.get_width() / slide.frame_count
		var frame_height := slide.texture.get_height()
		for i in range(slide.frame_count):
			var atlas := AtlasTexture.new()
			atlas.atlas = slide.texture
			atlas.region = Rect2(i * frame_width, 0, frame_width, frame_height)
			frames.add_frame("play", atlas)
		_anim_display.sprite_frames = frames
		_anim_display.play("play")
	else:
		_anim_display.visible = false
		_static_display.visible = true
		_static_display.texture = slide.texture

func _next_slide() -> void:
	_slide_index += 1
	if _slide_index >= slides.size():
		_finish()
		return
	_fading = true
	await _fade_to(1.0)
	_show_slide(_slide_index)
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
	get_tree().change_scene_to_file(GAME_SCENE)
