class_name DungeonGenerator
extends Node2D

const ROOM_SIZE: int = 1024

const _SPECIAL_TYPES := [Room.RoomType.START, Room.RoomType.BOSS, Room.RoomType.TREASURE]

const DIR_NAMES := ["N", "S", "E", "W"]

const DIRS := {
	"N": Vector2i(0, -1),
	"S": Vector2i(0, 1),
	"E": Vector2i(1, 0),
	"W": Vector2i(-1, 0),
}

const OPPOSITE := {"N": "S", "S": "N", "E": "W", "W": "E"}

@export var room_pool: Array[PackedScene] = []
@export var target_room_count: int = 9
@export var branch_chance: float = 0.5
@export_range(0, 4294967295) var rng_seed: int = 0
@export var regenerate_on_ready: bool = true

var _rng := RandomNumberGenerator.new()
var _prototypes: Array[Dictionary] = []
var _supported_signatures: Dictionary = {}

func _ready() -> void:
	if regenerate_on_ready:
		generate()

func generate() -> void:
	_clear_children()

	if room_pool.is_empty():
		push_error("DungeonGenerator: room_pool is empty. Assign at least one Room scene in the Inspector.")
		return
#test
	_rng.seed = rng_seed if rng_seed != 0 else randi()
	_build_prototypes()
	_compute_supported_signatures()

	var plan := _plan_layout()
	var special := _assign_special_rooms(plan)
	_instantiate_rooms(plan, special)

func _clear_children() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()

func _build_prototypes() -> void:
	_prototypes.clear()
	for scene in room_pool:
		if scene == null:
			continue
		var inst := scene.instantiate() as Room
		if inst == null:
			push_warning("DungeonGenerator: scene %s is not a Room (missing room.gd script)." % scene.resource_path)
			continue
		_prototypes.append({
			"scene": scene,
			"doors": inst.available_doors.duplicate(),
			"type": inst.room_type,
		})
		inst.free()

# Enumerate all 16 possible door subsets and mark which ones the current pool
# can cover (i.e. some prototype's doors are a superset of that subset).
func _compute_supported_signatures() -> void:
	_supported_signatures.clear()
	var missing: Array[String] = []
	for mask in range(16):
		var required: Array[String] = []
		for i in range(4):
			if mask & (1 << i):
				required.append(DIR_NAMES[i])
		var sig := _sig_string(required)
		if _pool_has_superset(required):
			_supported_signatures[sig] = true
		else:
			missing.append(sig if sig != "" else "(empty)")
	if not missing.is_empty():
		push_warning("DungeonGenerator: pool cannot cover door signatures %s. Layouts will avoid these." % [missing])

func _pool_has_superset(required: Array[String]) -> bool:
	for p in _prototypes:
		var ok := true
		for d in required:
			if d not in p.doors:
				ok = false
				break
		if ok:
			return true
	return false

func _sig_string(dirs: Array[String]) -> String:
	var parts: Array[String] = []
	for d in DIR_NAMES:
		if d in dirs:
			parts.append(d)
	return "".join(parts)

func _signature_of(grid: Dictionary, cell: Vector2i) -> String:
	var parts: Array[String] = []
	for d in DIR_NAMES:
		if grid.has(cell + DIRS[d]):
			parts.append(d)
	return _sig_string(parts)

func _expansion_is_valid(grid: Dictionary, from_cell: Vector2i, new_cell: Vector2i) -> bool:
	var affected: Array[Vector2i] = [from_cell, new_cell]
	for d in DIR_NAMES:
		var adj: Vector2i = new_cell + DIRS[d]
		if adj != from_cell and grid.has(adj):
			affected.append(adj)
	for c in affected:
		if not _supported_signatures.has(_signature_of(grid, c)):
			return false
	return true

const _MAX_PLAN_ATTEMPTS: int = 8

func _plan_layout() -> Dictionary:
	var best := {Vector2i.ZERO: true}
	for attempt in range(_MAX_PLAN_ATTEMPTS):
		var plan := _attempt_plan()
		if plan.size() >= target_room_count:
			return plan
		if plan.size() > best.size():
			best = plan
	push_warning("DungeonGenerator: could not reach target_room_count=%d after %d attempts; using best plan with %d rooms." % [target_room_count, _MAX_PLAN_ATTEMPTS, best.size()])
	return best

func _attempt_plan() -> Dictionary:
	var grid := {Vector2i.ZERO: true}
	var frontier: Array[Vector2i] = [Vector2i.ZERO]

	while grid.size() < target_room_count and not frontier.is_empty():
		var idx := _rng.randi_range(0, frontier.size() - 1)
		var cell: Vector2i = frontier[idx]

		var dirs := DIRS.keys()
		dirs.shuffle()
		var expanded := false

		for dir in dirs:
			if grid.size() >= target_room_count:
				break
			var neighbor: Vector2i = cell + DIRS[dir]
			if grid.has(neighbor):
				continue
			if _rng.randf() > branch_chance:
				continue

			grid[neighbor] = true
			if not _expansion_is_valid(grid, cell, neighbor):
				grid.erase(neighbor)
				continue

			frontier.append(neighbor)
			expanded = true

		if not expanded:
			frontier.remove_at(idx)

	return grid

func _neighbor_count(grid: Dictionary, cell: Vector2i) -> int:
	var n := 0
	for d in DIR_NAMES:
		if grid.has(cell + DIRS[d]):
			n += 1
	return n

func _bfs_distances(grid: Dictionary, source: Vector2i) -> Dictionary:
	var dist := {source: 0}
	var queue: Array[Vector2i] = [source]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for d in DIR_NAMES:
			var n: Vector2i = cell + DIRS[d]
			if grid.has(n) and not dist.has(n):
				dist[n] = int(dist[cell]) + 1
				queue.append(n)
	return dist

# START at origin. BOSS at farthest dead-end from start. TREASURE at the next-
# farthest dead-end (if any), giving the classic Isaac side-path feel.
func _assign_special_rooms(grid: Dictionary) -> Dictionary:
	var special := {Vector2i.ZERO: Room.RoomType.START}
	if grid.size() <= 1:
		return special

	var dist := _bfs_distances(grid, Vector2i.ZERO)
	var dead_ends: Array = []
	for cell in grid.keys():
		if cell == Vector2i.ZERO:
			continue
		if _neighbor_count(grid, cell) != 1:
			continue
		dead_ends.append({"cell": cell, "dist": int(dist.get(cell, -1))})
	dead_ends.sort_custom(func(a, b): return a.dist > b.dist)

	if dead_ends.size() >= 1 and dead_ends[0].dist > 0:
		special[dead_ends[0].cell] = Room.RoomType.BOSS
	if dead_ends.size() >= 2 and dead_ends[1].dist > 0:
		special[dead_ends[1].cell] = Room.RoomType.TREASURE
	return special

func _instantiate_rooms(grid: Dictionary, special: Dictionary) -> void:
	for cell in grid.keys():
		var required: Array[String] = []
		for dir in DIR_NAMES:
			if grid.has(cell + DIRS[dir]):
				required.append(dir)

		var assigned_type: int = special.get(cell, Room.RoomType.NORMAL)
		var chosen := _pick_room_for(required, assigned_type)
		if chosen.is_empty():
			push_warning("DungeonGenerator: no room in pool supports doors %s at cell %s." % [required, cell])
			continue

		var instance := (chosen.scene as PackedScene).instantiate() as Room
		instance.position = Vector2(cell.x * ROOM_SIZE, cell.y * ROOM_SIZE)
		instance.room_type = assigned_type
		add_child(instance)

# Tier 1: exact door-signature match.
# Tier 2: superset – any room whose doors are a superset of required.
# Tier 3: best-match fallback so the dungeon still renders (with a warning).
# Special cells (START/BOSS/TREASURE) are restricted to matching-type prototypes;
# normal cells exclude special-type prototypes so they don't leak in.
func _pick_room_for(required: Array[String], required_type: int = Room.RoomType.NORMAL) -> Dictionary:
	var type_pool: Array[Dictionary] = []
	var is_special := required_type in _SPECIAL_TYPES
	for p in _prototypes:
		if is_special:
			if p.type == required_type:
				type_pool.append(p)
		else:
			if p.type not in _SPECIAL_TYPES:
				type_pool.append(p)

	if type_pool.is_empty():
		if is_special:
			push_warning("DungeonGenerator: no prototype with room_type=%d; falling back to full pool." % required_type)
		type_pool = _prototypes

	var required_count := required.size()
	var exact: Array[Dictionary] = []
	for p in type_pool:
		if (p.doors as Array).size() != required_count:
			continue
		var ok := true
		for d in required:
			if d not in p.doors:
				ok = false
				break
		if ok:
			exact.append(p)
	if not exact.is_empty():
		return exact[_rng.randi_range(0, exact.size() - 1)]

	var supersets: Array[Dictionary] = []
	for p in type_pool:
		var ok := true
		for d in required:
			if d not in p.doors:
				ok = false
				break
		if ok:
			supersets.append(p)
	if not supersets.is_empty():
		return supersets[_rng.randi_range(0, supersets.size() - 1)]

	var best_score := -1
	var best: Array[Dictionary] = []
	for p in type_pool:
		var score := 0
		for d in required:
			if d in p.doors:
				score += 1
		if score > best_score:
			best_score = score
			best = [p]
		elif score == best_score:
			best.append(p)
	if best.is_empty():
		return {}
	push_warning("DungeonGenerator: no exact fit for doors %s; using best-match (%d/%d doors)." % [required, best_score, required.size()])
	return best[_rng.randi_range(0, best.size() - 1)]
