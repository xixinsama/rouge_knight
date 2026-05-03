extends Area2D
class_name HitboxComponent

signal hit(hurtbox: HurtboxComponent)

@export var damage: int = 10
@export var active: bool = false:
	set(value):
		active = value
		_update_collision()

## 弹反时子弹的新归属（仅弹反区域需要设置）
@export var parry_owner: Node2D


func _ready() -> void:
	area_entered.connect(_on_area_entered)
	_update_collision()


func _update_collision() -> void:
	set_deferred("monitorable", active)


func register_hit(hurtbox: HurtboxComponent) -> void:
	hit.emit(hurtbox)


func _on_area_entered(area: Area2D) -> void:
	if not active:
		return

	if area is Bullet:
		if parry_owner and area.owner != parry_owner:
			area.parry(parry_owner)
