extends CharacterBody2D

const MOVE_SPEED = 300.0
const KNOCKBACK_DECAY = 1800.0

## Used only when the mob isn't a child of a Room. Keeps free-placed test mobs
## reasonable. <= 0 means "always aggro".
@export var aggro_radius: float = 0.0

var health = 100
var knockback_velocity = Vector2.ZERO
var player: Node2D
var _room: Room

func _ready():
	%Slime.play_walk()
	_refresh_player()
	_room = _find_owning_room()

func _physics_process(delta):
	if not is_instance_valid(player):
		_refresh_player()

	var chase_velocity := Vector2.ZERO
	if is_instance_valid(player) and _player_in_aggro():
		var direction := global_position.direction_to(player.global_position)
		chase_velocity = direction * MOVE_SPEED

	velocity = chase_velocity + knockback_velocity
	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, KNOCKBACK_DECAY * delta)
	move_and_slide()

func take_damage(hit_direction: Vector2 = Vector2.ZERO, force: float = 500.0):
	health = health - 30
	%Slime.play_hurt()
	if hit_direction != Vector2.ZERO:
		knockback_velocity += hit_direction.normalized() * force

	if health < 0:
		queue_free()

		const SMOKE_SCENE = preload("res://smoke_explosion/smoke_explosion.tscn")
		var smoke = SMOKE_SCENE.instantiate()
		get_parent().add_child(smoke)
		smoke.global_position = global_position

func _refresh_player() -> void:
	player = get_tree().get_first_node_in_group("player") as Node2D

# Prefer room-based aggro: only chase when the player is inside our room's
# bounds. If we're not inside a Room (e.g. the dungeon test scene), fall back
# to a simple distance check.
func _player_in_aggro() -> bool:
	if _room != null:
		var room_rect := Rect2(_room.global_position, Vector2(Room.ROOM_SIZE, Room.ROOM_SIZE))
		return room_rect.has_point(player.global_position)
	if aggro_radius > 0.0:
		return global_position.distance_to(player.global_position) <= aggro_radius
	return true

func _find_owning_room() -> Room:
	var node: Node = get_parent()
	while node != null:
		if node is Room:
			return node
		node = node.get_parent()
	return null
