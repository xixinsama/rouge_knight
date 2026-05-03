## 敌怪攻击基类
## 提供冷却计时、攻击范围检查与子类可复写的 _perform_attack 流程
## 子类在 _perform_attack 中实现具体攻击逻辑后，应尽早发出 attack_finished；
## 若子类未发出，基类会在冷却结束时兜底发出，避免状态机卡死
extends Node
class_name EnemyAttack

## 攻击动作开始（进入冷却）
signal attack_started
## 攻击动作结束，状态机收到后切回 CHASE
signal attack_finished

## 单次命中伤害
@export var damage: int = 10
## 攻击冷却间隔（秒）
@export var attack_interval: float = 1.5
## 攻击判定距离
@export var attack_range: float = 50.0

var _can_attack: bool = true
var _attack_timer: float = 0.0


func _process(delta: float) -> void:
	if not _can_attack:
		_attack_timer -= delta
		if _attack_timer <= 0.0:
			_can_attack = true
			# 兜底：冷却结束时发出 attack_finished，防止子类忘记发导致状态机卡死
			attack_finished.emit()


## 由状态机每帧调用，冷却就绪且目标在范围内时执行攻击
func try_attack(target: Node2D) -> bool:
	if not _can_attack:
		return false
	var dist := (get_parent() as Node2D).global_position.distance_to(target.global_position)
	if dist > attack_range:
		return false
	_perform_attack(target)
	return true


## 子类复写以实现具体攻击行为，必须调用 super() 以进入冷却
func _perform_attack(_target: Node2D) -> void:
	_can_attack = false
	_attack_timer = attack_interval
	attack_started.emit()
