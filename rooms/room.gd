class_name Room
extends Node2D

enum RoomType { START, NORMAL, BOSS, TREASURE }

const ROOM_SIZE: int = 1024
const CHEST_SCENE: PackedScene = preload("res://chest.tscn")
const DEFAULT_MOB_SCENE: PackedScene = preload("res://mob1.tscn")
const DOOR_SCENE: PackedScene = preload("res://door.tscn")
const DOOR_SEAL_SCENE: PackedScene = preload("res://rooms/extras/door_seal/door_seal.tscn")

signal cleared(room: Room)
signal player_entered(room: Room)

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
@export var spawn_enemies_on_ready: bool = false

@export_group("Clearing")
## If true, doors lock behind the player until every spawned mob is dead.
@export var locks_doors_when_entered: bool = true
## How far past the wall the player must be before doors spawn behind them.
## Prevents new doors from spawning on top of the player as they cross
## a doorway.
@export var entry_lock_inset: float = 60.0
## How far from the room edge counts as a perimeter wall for wisp line-of-sight.
@export var perimeter_wall_thickness: float = 128.0

var is_cleared: bool = false
var _chest: Chest
var _spawned_mobs: Array[Node2D] = []
var _doors_locked: bool = false
var _active_doors: Array[Door] = []
var _player_was_inside: bool = false
var _enemy_setup_pending: bool = false
var _dungeon_connected_doors: Array[String] = []
var _dungeon_connections_applied: bool = false

func _ready() -> void:
	_hide_door_placeholders()
	if _dungeon_connections_applied:
		_spawn_door_seals()
	call_deferred("_setup_world_entities")

## Called by DungeonGenerator before the room enters the tree. Seals any
## available_doors that are not connected to a neighboring cell.
func set_dungeon_connections(connected: Array[String]) -> void:
	_dungeon_connected_doors = connected.duplicate()
	_dungeon_connections_applied = true

func _setup_world_entities() -> void:
	if not is_inside_tree():
		return
	if room_type == RoomType.TREASURE:
		_spawn_treasure_chest()
	if spawn_enemies_on_ready and _should_spawn_enemies():
		_spawn_enemies()
	_promote_props()
	_promote_chests()
	_promote_enemies()
	_update_cleared_from_mobs()

func _promote_chests() -> void:
	_promote_chest_nodes_under(self)
	var props_root := get_node_or_null("Props")
	if props_root != null:
		_promote_chest_nodes_under(props_root)

func _promote_chest_nodes_under(root: Node) -> void:
	for child in root.get_children():
		if child is Chest:
			WorldLayer.promote(child as Node2D)

func _promote_props() -> void:
	var props_root := get_node_or_null("Props")
	if props_root != null:
		for child in props_root.get_children():
			if child is Node2D:
				WorldLayer.promote(child as Node2D)
	# Props placed as direct children of the room (outside Props/) still need World
	# promotion or they draw in the Dungeon layer on top of the player.
	for child in get_children():
		if child is RoomProp:
			WorldLayer.promote(child)

func _promote_enemies() -> void:
	var enemies_root := get_node_or_null("Enemies")
	if enemies_root != null:
		var pending: Array[Node2D] = []
		for child in enemies_root.get_children():
			if child is Node2D:
				pending.append(child as Node2D)
		var world := WorldLayer.find_world(self)
		for mob in pending:
			_track_mob(mob)
			if world != null:
				WorldLayer.promote(mob)
		if world == null and not pending.is_empty() and not _enemy_setup_pending:
			_enemy_setup_pending = true
			call_deferred("_finish_enemy_setup")
			return
	_collect_enemies_by_meta()
	_enemy_setup_pending = false

func _finish_enemy_setup() -> void:
	_enemy_setup_pending = false
	_promote_enemies()
	_update_cleared_from_mobs()

func _track_mob(mob: Node2D) -> void:
	mob.set_meta(&"owning_room", self)
	if mob not in _spawned_mobs:
		_spawned_mobs.append(mob)

func _collect_enemies_by_meta() -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		if node is Node2D and node.get_meta(&"owning_room", null) == self:
			_track_mob(node as Node2D)

func _update_cleared_from_mobs() -> void:
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
	var inside := _player_currently_inside()
	if inside and not _player_was_inside:
		# Setup can mark the room cleared before World exists; fix on first entry.
		if is_cleared and _has_live_mobs():
			is_cleared = false
		player_entered.emit(self)
	if is_cleared or _doors_locked or not locks_doors_when_entered:
		_player_was_inside = inside
		return
	if inside and not _player_was_inside and _has_live_mobs():
		_lock_doors()
	_player_was_inside = inside

func _player_currently_inside() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return false
	return contains_global_point(player.global_position)

func contains_global_point(global_pos: Vector2, inset: float = -1.0) -> bool:
	if inset < 0.0:
		inset = entry_lock_inset
	var rect := Rect2(
		global_position + Vector2(inset, inset),
		Vector2(ROOM_SIZE - inset * 2.0, ROOM_SIZE - inset * 2.0),
	)
	return rect.has_point(global_pos)

func is_perimeter_world_point(world_pos: Vector2) -> bool:
	var local := to_local(world_pos)
	var edge := perimeter_wall_thickness
	return (
		local.x < edge
		or local.x > ROOM_SIZE - edge
		or local.y < edge
		or local.y > ROOM_SIZE - edge
	)

func _has_live_mobs() -> bool:
	_prune_dead_mobs()
	for m in _spawned_mobs:
		if _is_live_mob(m):
			return true
	_collect_enemies_by_meta()
	_prune_dead_mobs()
	for m in _spawned_mobs:
		if _is_live_mob(m):
			return true
	return false

func _is_live_mob(mob: Node) -> bool:
	# Corpses stay in the tree for death animations but leave the "enemies" group.
	return is_instance_valid(mob) and mob.is_in_group("enemies")

func _prune_dead_mobs() -> void:
	for i in range(_spawned_mobs.size() - 1, -1, -1):
		if not _is_live_mob(_spawned_mobs[i]):
			_spawned_mobs.remove_at(i)

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
			d.open()
	_active_doors.clear()
	cleared.emit(self)

# Spawns one chest per ChestSpawn marker found in the room.
# Looks in three places (in order): a "ChestSpawns" container node, any Marker2D
# whose name starts with "ChestSpawn" inside the "Spawns" node, or a single
# "ChestSpawn" direct child. Falls back to room center when none are found.
func _spawn_treasure_chest() -> void:
	# 1. Dedicated container node named "ChestSpawns".
	var container := get_node_or_null("ChestSpawns")
	if container != null:
		for child in container.get_children():
			if child is Node2D:
				_spawn_one_chest((child as Node2D).global_position)
		return

	# 2. Markers under the shared "Spawns" node whose name starts with "ChestSpawn".
	var spawns_node := get_node_or_null("Spawns")
	if spawns_node != null:
		var found := false
		for child in spawns_node.get_children():
			if child is Marker2D and (child.name as String).begins_with("ChestSpawn"):
				_spawn_one_chest((child as Marker2D).global_position)
				found = true
		if found:
			return

	# 3. Single "ChestSpawn" as a direct child of the Room.
	var marker := get_node_or_null("ChestSpawn") as Marker2D
	if marker != null:
		_spawn_one_chest(marker.global_position)
		return

	# 4. Fallback: room center.
	_spawn_one_chest(global_position + Vector2(ROOM_SIZE / 2.0, ROOM_SIZE / 2.0))

func _spawn_one_chest(world_pos: Vector2) -> void:
	var chest := CHEST_SCENE.instantiate() as Chest
	if chest == null:
		return
	WorldLayer.add_entity(self, chest, world_pos)
	if _chest == null:
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
		WorldLayer.add_entity(self, mob, global_position + pos)
		_track_mob(mob)

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

# Orange ColorRects under Doors/* are editor layout guides only.
func _spawn_door_seals() -> void:
	var wall_tex := _get_room_background_texture()
	for direction in available_doors:
		if direction in _dungeon_connected_doors:
			continue
		var seal := DOOR_SEAL_SCENE.instantiate() as DoorSeal
		if seal == null:
			continue
		add_child(seal)
		seal.setup(direction, wall_tex)
		_enable_perimeter_bridge(direction)

func _get_room_background_texture() -> Texture2D:
	var bg := get_node_or_null("Background") as Sprite2D
	if bg == null or bg.texture == null:
		return null
	return bg.texture

func _get_room_background_scale() -> float:
	var bg := get_node_or_null("Background") as Sprite2D
	if bg == null:
		return 2.0
	return maxf(absf(bg.scale.x), absf(bg.scale.y))

func _enable_perimeter_bridge(direction: String) -> void:
	var walls := get_node_or_null("RoomWalls") as StaticBody2D
	if walls == null:
		return
	var bridge_name := "%s_Bridge" % direction
	var bridge := walls.get_node_or_null(bridge_name) as CollisionShape2D
	if bridge != null:
		bridge.disabled = false

func _hide_door_placeholders() -> void:
	var doors_root := get_node_or_null("Doors")
	if doors_root == null:
		return
	for marker in doors_root.get_children():
		for child in marker.get_children():
			if child is CanvasItem:
				child.visible = false

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
