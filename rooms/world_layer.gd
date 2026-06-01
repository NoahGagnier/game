class_name WorldLayer
extends Node2D

static var _instance: WorldLayer

func _enter_tree() -> void:
	add_to_group("world")
	_instance = self

func _exit_tree() -> void:
	if _instance == self:
		_instance = null

static func find_world(from: Node = null) -> WorldLayer:
	if _instance != null and is_instance_valid(_instance):
		return _instance
	if from == null or not from.is_inside_tree():
		return null
	var tree := from.get_tree()
	if tree == null:
		return null
	return tree.get_first_node_in_group("world") as WorldLayer

static func promote(node: Node2D) -> void:
	if node == null or not node.is_inside_tree():
		return
	var world := find_world(node)
	if world == null or node.get_parent() == world:
		return
	var global_pos := node.global_position
	node.reparent(world)
	node.global_position = global_pos

static func add_entity(from: Node, entity: Node2D, global_pos: Vector2) -> void:
	if entity == null:
		return
	var world := find_world(from)
	if world == null:
		push_warning("WorldLayer: no World node found in scene.")
		return
	world.add_child(entity)
	entity.global_position = global_pos
