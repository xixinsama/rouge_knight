class_name SpawnerComponent
## 实例化子场景组件
extends Node2D

@export var scene: PackedScene
@export var parent_node: Node = self

var spawned_nodes: Dictionary = {}
var no_mapping_nodes: Array = []

## 生成位置，生成标记，网格坐标映射
func spawn(global_spawn_position: Vector2 = global_position, flag: int = 0, grid_pos: Vector2i = Vector2i.MAX) -> Node:
	assert(scene is PackedScene, "Error: The scene export was never set on this spawner component.")
	if parent_node == null:
		parent_node = get_tree().current_scene
		
	var instance = scene.instantiate()
	parent_node.add_child(instance)
	instance.global_position = global_spawn_position
	
	if instance.has_method("initialize"):
		instance.initialize(flag)
		
	# 核心修改：如果提供了有效的网格坐标，则记录映射
	if grid_pos != Vector2i.MAX:
		if spawned_nodes.has(grid_pos):
			print("覆盖映射，原对象将删除", grid_pos, "spawner_componnet.gd")
			if is_instance_valid(spawned_nodes[grid_pos]):
				spawned_nodes[grid_pos].queue_free()
		spawned_nodes[grid_pos] = instance
	else:
		no_mapping_nodes.append(instance)
	
	return instance

## 新增：通过网格坐标获取节点
func get_node_at(grid_pos: Vector2i) -> Node:
	var scene_node = spawned_nodes.get(grid_pos, null)
	if is_instance_valid(scene_node):
		return scene_node
	return null

## 清除节点
func clear_maped() -> void:
	for node in spawned_nodes.values():
		if is_instance_valid(node):
			node.queue_free()
	spawned_nodes.clear()

func clear_nomaped() -> void:
	for node in no_mapping_nodes:
		if is_instance_valid(node):
			node.queue_free()
	no_mapping_nodes.clear()

func clear_all() -> void:
	clear_maped()
	clear_nomaped()
