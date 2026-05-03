extends Area2D
class_name Bullet ## 已使用_process

## 弹幕数据（由工厂在 spawn 时设置）
@export var data: BulletData
## 当前归属（发射者或被弹反后的新归属）
@export var bullet_owner: Node2D = null
## 当前飞行方向
@export var direction: Vector2
## 当前速度（从 initial_speed 加速到 max_speed）
@export var current_speed: float


func activate(bullet_data: BulletData, start_pos: Vector2, dir: Vector2, shooter: Node2D) -> void:
	data = bullet_data
	bullet_owner = shooter
	direction = dir.normalized()
	current_speed = bullet_data.initial_speed
	global_position = start_pos
	show()
	set_process(true)
	call_deferred(&"set_monitorable", true)
	call_deferred(&"set_monitoring", true)


func deactivate() -> void:
	hide()
	set_process(false)
	call_deferred(&"set_monitorable", false)
	call_deferred(&"set_monitoring", false)
	Global.Bullet_Factory.return_bullet(self)


func parry(new_owner: Node2D) -> void:
	bullet_owner = new_owner
	direction = -direction


func _process(delta: float) -> void:
	current_speed = move_toward(current_speed, data.max_speed, data.acceleration * delta)
	position += direction * current_speed * delta
	
	rotation = lerp_angle(rotation, direction.angle(), delta * 10)
