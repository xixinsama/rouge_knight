extends Area2D
class_name HitboxComponent ## 攻击碰撞盒组件

## 击中信号：被击中的受击框
signal hit(hurtbox: HurtboxComponent)

## 攻击伤害值（可在编辑器中设置）
@export var damage: int = 10
## 攻击是否激活（可在动画中控制）
@export var active: bool = false:
	set(value):
		active = value
		_update_collision()

func _ready() -> void:
	_update_collision()

## 更新碰撞检测状态
func _update_collision() -> void:
	set_deferred("monitorable", active)

## 被受击框调用，表示已造成伤害
func register_hit(hurtbox: HurtboxComponent) -> void:
	hit.emit(hurtbox)
	active = false
