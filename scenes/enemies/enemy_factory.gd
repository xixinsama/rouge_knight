## 敌怪工厂 — 按配置生成敌怪实例
## 挂载到场景中，指定 enemy_scene（EnemyBase.tscn 骨架）和 player 引用，
## 然后 spawn(config, position) 即可实例化配置好的敌怪
extends Node
class_name EnemyFactory

## 敌怪基础场景（含组件骨架的 EnemyBase.tscn）
@export var enemy_scene: PackedScene
## 玩家引用
@export var player: Node2D

## 已生成的敌怪列表
var spawned_enemies: Array[BaseEnemy] = []


## 在指定位置生成一个敌怪
func spawn(config: EnemyConfig, position: Vector2) -> BaseEnemy:
	if not enemy_scene:
		push_error("EnemyFactory: enemy_scene not set")
		return null

	var enemy := enemy_scene.instantiate() as BaseEnemy
	enemy.config = config
	enemy.global_position = position
	add_child(enemy)
	spawned_enemies.append(enemy)
	return enemy


## 在标记节点的位置生成敌怪
func spawn_at_marker(config: EnemyConfig, marker: Node2D) -> BaseEnemy:
	return spawn(config, marker.global_position)


## 清除所有已生成的敌怪
func clear_all() -> void:
	for e in spawned_enemies:
		if is_instance_valid(e):
			e.queue_free()
	spawned_enemies.clear()
