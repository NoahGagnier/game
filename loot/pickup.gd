class_name Pickup
extends Area2D

signal picked_up(pickup: Pickup)

@export var pop_height: float = 40.0
@export var pop_duration: float = 0.45
@export var bob_amplitude: float = 3.0
@export var bob_speed: float = 0.7

# Item card shown when this pickup is collected.
@export var item_name: String = ""
@export_multiline var item_description: String = ""
@export var item_icon: Texture2D
@export var item_icon_ui_shadow: bool = false

@export_group("Drop Shadow")
@export var shadow_enabled: bool = true
@export var shadow_color: Color = Color(0.0, 0.0, 0.0, 0.45)
@export var shadow_offset: Vector2 = Vector2(1.0, 2.0)

var _popping: bool = false
var _pickup_locked: bool = false
var _bob_time: float = 0.0
var _bob_origin: float = 0.0

func sync_bob_origin() -> void:
	_bob_origin = position.y

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	sync_bob_origin()
	if shadow_enabled:
		_create_drop_shadows()

func _create_drop_shadows() -> void:
	var visuals: Array[Node] = []
	for child in get_children():
		if child is Sprite2D or child is AnimatedSprite2D:
			visuals.append(child)
	for visual in visuals:
		var shadow := visual.duplicate(DUPLICATE_USE_INSTANTIATION) as CanvasItem
		if shadow == null:
			continue
		shadow.name = String(visual.name) + "Shadow"
		shadow.modulate = shadow_color
		shadow.self_modulate = Color(1, 1, 1, 1)
		(shadow as Node2D).position = (visual as Node2D).position + shadow_offset
		shadow.z_as_relative = (visual as CanvasItem).z_as_relative
		shadow.z_index = (visual as CanvasItem).z_index - 1
		add_child(shadow)
		move_child(shadow, visual.get_index())

func _process(delta: float) -> void:
	if _popping:
		return
	_bob_time += delta
	position.y = _bob_origin + sin(_bob_time * TAU * bob_speed) * bob_amplitude

func _on_body_entered(body: Node2D) -> void:
	if _popping or _pickup_locked:
		return
	if body is Player:
		apply(body)
		if item_name != "" or item_description != "":
			ItemEvents.notify(item_name, item_description, item_icon, item_icon_ui_shadow)
		picked_up.emit(self)
		queue_free()

# Override in subclasses to define the pickup's effect.
func apply(_player: Player) -> void:
	pass

func lock_pickup() -> void:
	_pickup_locked = true

func start_pickup_lock(seconds: float) -> void:
	_pickup_locked = true
	get_tree().create_timer(seconds).timeout.connect(func() -> void:
		_pickup_locked = false
	)

# Arcs from current position to `target` over `pop_duration` seconds. The
# pickup cannot be collected while it's still in the air.
func pop_to(target: Vector2) -> void:
	_popping = true
	var start := global_position
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_method(
		func(t: float) -> void:
			var flat := start.lerp(target, t)
			var arc_y := -4.0 * pop_height * t * (1.0 - t)
			global_position = flat + Vector2(0.0, arc_y),
		0.0, 1.0, pop_duration
	)
	tween.tween_callback(func() -> void:
		_popping = false
		sync_bob_origin()
		_bob_time = 0.0
	)
