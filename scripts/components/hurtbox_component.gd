extends Area2D
class_name HurtboxComponent ## 受击碰撞盒组件

## 关联的血量组件（在编辑器中拖拽赋值）
@export var health_component: HealthComponent

func _ready() -> void:
	area_entered.connect(_on_area_entered)
	set_deferred(&"monitoring", true)

func _on_area_entered(area: Area2D) -> void:
	# 只处理 HitboxComponent 类型的攻击框
	if not area is HitboxComponent:
		return
	
	var hitbox := area as HitboxComponent
	
	# 血量组件存在且未死亡时造成伤害
	if health_component and not health_component.is_dead:
		health_component.take_damage(hitbox.damage)
		# 通知攻击框已击中，用于触发攻击方的特效/音效
		hitbox.register_hit(self)
