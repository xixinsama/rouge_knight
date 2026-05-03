## Godot 图标敌怪 — BaseEnemy 的子类，用于演示和测试
## 在编辑器中绘制扇形射线预览（可视化检测/避障范围）
@tool
class_name GodotEnemy
extends BaseEnemy

## 编辑器预览射线数量
@export var _editor_ray_count: int = 7:
	set(v):
		_editor_ray_count = v
		queue_redraw()
## 编辑器预览射线散布角度（度）
@export var _editor_ray_spread: float = 75.0:
	set(v):
		_editor_ray_spread = v
		queue_redraw()
## 编辑器预览射线长度
@export var _editor_ray_distance: float = 50.0:
	set(v):
		_editor_ray_distance = v
		queue_redraw()


func _ready() -> void:
	# 编辑器模式下仅绘制预览，不执行游戏逻辑
	if Engine.is_editor_hint():
		queue_redraw()
		return
	super()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var spread_rad := deg_to_rad(_editor_ray_spread)
	var half := spread_rad / 2.0
	var base_angle := Vector2.RIGHT.angle()
	for i in range(_editor_ray_count):
		var offset := 0.0
		if _editor_ray_count > 1:
			offset = lerpf(-half, half, float(i) / (_editor_ray_count - 1))
		var dir := Vector2.RIGHT.rotated(base_angle + offset)
		draw_line(Vector2.ZERO, dir * _editor_ray_distance, Color(0.3, 0.8, 1.0, 0.5), 0.8)
	draw_circle(Vector2.ZERO, 3.0, Color.WHITE)
