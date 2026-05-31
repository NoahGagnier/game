extends RefCounted

enum VisionMode { ALL_WALLS, PERIMETER_WALLS_ONLY }

const WALL_COLLISION_MASK := 1
const LOS_CLEARANCE := 16.0
const MELEE_LOS_RANGE := 64.0
const PERIMETER_RAY_STEP := 4.0
const MAX_PERIMETER_RAY_STEPS := 16

# True when the player is inside the room (with doorway inset), within range,
# and not blocked by wall collision.
static func can_target_player(
	enemy: Node2D,
	player: Node2D,
	room: Node,
	max_range: float = -1.0,
	vision_mode: VisionMode = VisionMode.ALL_WALLS,
) -> bool:
	if not is_instance_valid(enemy) or not is_instance_valid(player):
		return false
	if room != null and room.has_method("contains_global_point"):
		if not room.contains_global_point(player.global_position):
			return false
	if max_range > 0.0:
		if enemy.global_position.distance_squared_to(player.global_position) > max_range * max_range:
			return false
	match vision_mode:
		VisionMode.PERIMETER_WALLS_ONLY:
			return has_perimeter_line_of_sight(enemy, player, room)
		_:
			return has_line_of_sight(enemy, player)

static func has_line_of_sight(from_node: Node2D, to_node: Node2D) -> bool:
	var from := from_node.global_position
	var to := to_node.global_position
	var dist := from.distance_to(to)
	if dist <= 0.001:
		return true
	if dist <= MELEE_LOS_RANGE:
		return true

	var dir := (to - from) / dist
	var ray_start := from + dir * LOS_CLEARANCE
	var ray_end := to - dir * LOS_CLEARANCE
	if ray_start.distance_to(ray_end) <= 0.001:
		return true

	var space := from_node.get_world_2d().direct_space_state
	var params := PhysicsRayQueryParameters2D.create(ray_start, ray_end)
	params.collision_mask = WALL_COLLISION_MASK
	params.collide_with_areas = false
	params.collide_with_bodies = true
	params.exclude = _ray_exclude(from_node, to_node)

	var hit := space.intersect_ray(params)
	if hit.is_empty():
		return true
	return hit.position.distance_to(from) >= dist - LOS_CLEARANCE

# Wisps ignore interior props (tables, pillars) and only stop at room edges.
static func has_perimeter_line_of_sight(from_node: Node2D, to_node: Node2D, room: Node) -> bool:
	if room == null or not room.has_method("is_perimeter_world_point"):
		return has_line_of_sight(from_node, to_node)

	var from := from_node.global_position
	var to := to_node.global_position
	var dist := from.distance_to(to)
	if dist <= 0.001:
		return true
	if dist <= MELEE_LOS_RANGE:
		return true

	var dir := (to - from) / dist
	var ray_start := from + dir * LOS_CLEARANCE
	var ray_end := to - dir * LOS_CLEARANCE
	if ray_start.distance_to(ray_end) <= 0.001:
		return true

	var space := from_node.get_world_2d().direct_space_state
	var exclude := _ray_exclude(from_node, to_node)

	for _i in MAX_PERIMETER_RAY_STEPS:
		var params := PhysicsRayQueryParameters2D.create(ray_start, ray_end)
		params.collision_mask = WALL_COLLISION_MASK
		params.collide_with_areas = false
		params.collide_with_bodies = true
		params.exclude = exclude

		var hit := space.intersect_ray(params)
		if hit.is_empty():
			return true
		var hit_pos: Vector2 = hit.position
		if room.is_perimeter_world_point(hit_pos):
			return false

		var next_start: Vector2 = hit_pos + dir * PERIMETER_RAY_STEP
		if next_start.distance_to(ray_start) < 0.25:
			return true
		if next_start.distance_to(from) >= dist - LOS_CLEARANCE:
			return true
		ray_start = next_start

	return true

static func _ray_exclude(from_node: Node2D, to_node: Node2D) -> Array[RID]:
	var exclude: Array[RID] = [from_node.get_rid()]
	if to_node is CollisionObject2D:
		exclude.append((to_node as CollisionObject2D).get_rid())
	return exclude
