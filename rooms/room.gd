class_name Room
extends Node2D

enum RoomType { START, NORMAL, BOSS, TREASURE }

const ROOM_SIZE: int = 1024
const CHEST_SCENE: PackedScene = preload("res://chest.tscn")
const DEFAULT_MOB_SCENE: PackedScene = preload("res://mob1.tscn")
const DOOR_SCENE: PackedScene = preload("res://door.tscn")

signal cleared(room: Room)

@export var available_doors: Array[String] = ["N", "S", "E", "W"]
@export var room_type: RoomType = RoomType.NORMAL

@export_group("Enemies")
## If empty, the room falls back to DEFAULT_MOB_SCENE (slime) so every normal
## room is populated even before the pool is configured per-scene.
@export var mob_pool: Array[MobSpawn] = []
@export var enemies_min: int = 2
@export var enemies_max: int = 4
## Distance from each wall reserved as a no-spawn margin when scattering.
@export var spawn_margin: float = 160.0
@export var spawn_enemies_on_ready: bool = true

@export_group("Clearing")
## If true, doors lock behind the player until every spawned mob is dead.
@export var locks_doors_when_entered: bool = true

var is_cleared: bool = false
var _chest: Chest
var _spawned_mobs: Array[Node2D] = []
var _doors_locked: bool = false
var _active_doors: Array[Door] = []
var _player_was_inside: bool = false

func _ready() -> void:
	if room_type == RoomType.TREASURE:
		_spawn_treasure_chest()
	if spawn_enemies_on_ready and _should_spawn_enemies():
		_spawn_enemies()
	if not _has_live_mobs():
		is_cleared = true

func _physics_process(_delta: float) -> void:
	_update_entry_lock()
	if _doors_locked and not _has_live_mobs():
		_clear_room()

# Watches for the player to walk into the room. On the entry frame, locks doors
# if there are still live mobs. Once the room is cleared, further entries are
# no-ops.
func _update_entry_lock() -> void:
	if is_cleared or _doors_locked or not locks_doors_when_entered:
		_player_was_inside = _player_currently_inside()
		return
	var inside := _player_currently_inside()
	if inside and not _player_was_inside and _has_live_mobs():
		_lock_doors()
	_player_was_inside = inside

func _player_currently_inside() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return false
	var rect := Rect2(global_position, Vector2(ROOM_SIZE, ROOM_SIZE))
	return rect.has_point(player.global_position)

func _has_live_mobs() -> bool:
	for m in _spawned_mobs:
		if is_instance_valid(m):
			return true
	return false

func _lock_doors() -> void:
	if _doors_locked:
		return
	_doors_locked = true
	for direction in available_doors:
		var door := DOOR_SCENE.instantiate() as Door
		if door == null:
			continue
		add_child(door)
		door.position = get_door_local_position(direction)
		door.set_direction(direction)
		_active_doors.append(door)

func _clear_room() -> void:
	is_cleared = true
	_doors_locked = false
	for d in _active_doors:
		if is_instance_valid(d):
			d.queue_free()
	_active_doors.clear()
	cleared.emit(self)

# Places a chest at the room's center, unless the scene has a "ChestSpawn"
# Marker2D child to override the position.
func _spawn_treasure_chest() -> void:
	if _chest != null:
		return
	var chest := CHEST_SCENE.instantiate() as Chest
	if chest == null:
		return
	var marker := get_node_or_null("ChestSpawn") as Marker2D
	chest.position = marker.position if marker != null else Vector2(ROOM_SIZE / 2.0, ROOM_SIZE / 2.0)
	add_child(chest)
	_chest = chest

# Only normal rooms spawn mobs for now. Boss rooms get a dedicated boss later,
# treasure/start rooms stay safe.
func _should_spawn_enemies() -> bool:
	return room_type == RoomType.NORMAL

# Gathers spawn positions (markers first, scattered fallback otherwise) and
# instantiates one mob from the weighted pool at each.
func _spawn_enemies() -> void:
	var spawn_positions := _gather_spawn_positions()
	for pos in spawn_positions:
		var mob_scene := _pick_mob_scene()
		if mob_scene == null:
			continue
		var mob := mob_scene.instantiate() as Node2D
		if mob == null:
			continue
		add_child(mob)
		mob.position = pos
		_spawned_mobs.append(mob)

# If the room has a "MobSpawns" child container, one mob spawns at each of its
# Node2D children. Otherwise, enemies_min..enemies_max positions are scattered
# inside the inner walkable area.
func _gather_spawn_positions() -> Array[Vector2]:
	var positions: Array[Vector2] = []
	var markers_root := get_node_or_null("MobSpawns")
	if markers_root != null:
		for child in markers_root.get_children():
			if child is Node2D:
				positions.append((child as Node2D).position)
		return positions

	var count := randi_range(enemies_min, enemies_max)
	for i in count:
		var x := randf_range(spawn_margin, ROOM_SIZE - spawn_margin)
		var y := randf_range(spawn_margin, ROOM_SIZE - spawn_margin)
		positions.append(Vector2(x, y))
	return positions

# Rolls mob_pool by weight. When the pool is empty, falls back to the default
# mob so rooms are never empty while new enemy types are being authored.
func _pick_mob_scene() -> PackedScene:
	if mob_pool.is_empty():
		return DEFAULT_MOB_SCENE

	var total := 0.0
	for e in mob_pool:
		if e != null and e.scene != null and e.weight > 0.0:
			total += e.weight
	if total <= 0.0:
		return null

	var roll := randf() * total
	var acc := 0.0
	for e in mob_pool:
		if e == null or e.scene == null or e.weight <= 0.0:
			continue
		acc += e.weight
		if roll <= acc:
			return e.scene
	return null

func get_door_local_position(direction: String) -> Vector2:
	match direction:
		"N": return Vector2(ROOM_SIZE / 2.0, 0)
		"S": return Vector2(ROOM_SIZE / 2.0, ROOM_SIZE)
		"E": return Vector2(ROOM_SIZE, ROOM_SIZE / 2.0)
		"W": return Vector2(0, ROOM_SIZE / 2.0)
	return Vector2.ZERO

func has_door(direction: String) -> bool:
	return direction in available_doors

func get_door_signature() -> String:
	var parts := ["N", "S", "E", "W"].filter(func(d): return d in available_doors)
	return "".join(parts)
