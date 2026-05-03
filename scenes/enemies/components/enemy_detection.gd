## 敌怪检测组件 — 基于距离检测玩家，发出 player_detected / player_lost 信号
## 在 _ready() 中通过 "player" 组查找玩家引用，每帧检查距离是否在 detection_radius 内
extends Node
class_name EnemyDetection

## 玩家进入检测范围
signal player_detected(player: Node2D)
## 玩家离开检测范围
signal player_lost

## 检测半径（像素）
@export var detection_radius: float = 300.0
## 是否需要视线检测（当前未实现）
@export var use_line_of_sight: bool = false

var player_ref: Node2D
var is_player_detected: bool = false


func _ready() -> void:
	# 优先从 "player" 组查找
	var tree := get_tree()
	if tree:
		player_ref = tree.get_first_node_in_group(&"player")
		if not player_ref:
			# 退而查找当前场景根节点的 "Player" 子节点
			var root := tree.current_scene
			if root:
				player_ref = root.get_node_or_null("Player") as Node2D


func _process(_delta: float) -> void:
	if not player_ref:
		return

	var dist: float = (get_parent() as Node2D).global_position.distance_to(player_ref.global_position)
	var in_range := dist <= detection_radius

	if in_range != is_player_detected:
		is_player_detected = in_range
		if in_range:
			player_detected.emit(player_ref)
		else:
			player_lost.emit()
