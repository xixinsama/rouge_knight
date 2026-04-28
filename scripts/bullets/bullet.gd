extends Area2D
class_name Bullet

## 子弹的移动速度
var speed: float = 0.0
## 移动方向（单位向量）
var direction: Vector2 = Vector2.ZERO

## 激活时调用，初始化子弹状态
func activate(start_pos: Vector2, dir: Vector2, spd: float) -> void:
	global_position = start_pos
	direction = dir.normalized()
	speed = spd
	show()
	set_process(true)
	# 如有碰撞，重新启用监视
	call_deferred(&"set_monitorable", true)
	call_deferred(&"set_monitoring", true)

## 停用子弹并归还对象池
func deactivate() -> void:
	hide()
	set_process(false)
	call_deferred(&"set_monitorable", false)
	call_deferred(&"set_monitoring", false)
	# 通知工厂回收本子弹
	Global.Bullet_Factory.return_bullet(self)

## 每帧移动，超出边界自动回收
func _process(delta: float) -> void:
	position += direction * speed * delta
	# 简单边界检查（根据屏幕尺寸调整）
	#var screen_size = get_viewport_rect().size
	#if position.x < -50 or position.x > screen_size.x + 50 or \
	   #position.y < -50 or position.y > screen_size.y + 50:
		#deactivate()
