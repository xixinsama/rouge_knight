extends Area2D
class_name HitboxComponent

signal hit(hurtbox: HurtboxComponent)

@export var active: bool = false:
	set(v):
		active = v
		set_deferred("monitorable", v)
		set_deferred("monitoring", v)

@export var parry_owner: Node2D = null

func _ready():
	area_entered.connect(_on_area_entered)

func _on_area_entered(area: Area2D):
	if not active: return
	if area is Bullet:
		if parry_owner and area.owner != parry_owner:
			area.parry(parry_owner)

## 由外部攻击组件调用，传递伤害信息
func register_hit(hurtbox: HurtboxComponent) -> void:
	hit.emit(hurtbox)
