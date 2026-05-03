extends Camera2D
class_name CameraController

static var current: CameraController

@export_group("ZoomControl")
## 缩放输入动作名称
@export var zoom_in_action: StringName = "zoom_in"
@export var zoom_out_action: StringName = "zoom_out"
## 最小/最大缩放值
@export var min_zoom: Vector2 = Vector2(0.5, 0.5)
@export var max_zoom: Vector2 = Vector2(2.0, 2.0)
## 缩放变化速度
@export var zoom_speed: float = 3.0

@export_group("TargetFollow")
## 要跟随的目标节点
@export var target: Node2D
## 目标节点中用于偏移的 Vector2 属性名
@export var look_ahead_property: StringName = "velocity"
## 偏移系数：预瞄/滞后强度。正值=镜头朝速度方向前探，负值=滞后
@export var offset_factor: float = 0.0
## 跟随平滑速度
@export var follow_speed: float = 800.0

# 内部变量
var _target_zoom: Vector2

func _ready() -> void:
	current = self
	_target_zoom = self.zoom
	# 初始化抖动状态（已在声明时赋值，此处可选）
	_shake_duration = 0.0

func _physics_process(delta: float) -> void:
	# 1. 处理缩放输入
	_handle_zoom_input(delta)
	
	# 2. 跟随目标（包含偏移计算）
	if target:
		_follow_target(delta)

func _handle_zoom_input(delta: float) -> void:
	var zoom_delta := 0.0
	if Input.is_action_just_pressed(zoom_in_action):
		zoom_delta = -zoom_speed * delta
	elif Input.is_action_just_pressed(zoom_out_action):
		zoom_delta = zoom_speed * delta
	
	if zoom_delta != 0.0:
		_target_zoom += Vector2(zoom_delta, zoom_delta)
		_target_zoom = _target_zoom.clamp(min_zoom, max_zoom)
	
	# 平滑缩放（使用与移动一致的平滑方式）
	zoom = zoom.lerp(_target_zoom, 1.0 - exp(-zoom_speed * delta))


func _follow_target(delta: float) -> void:
	# 计算基础目标位置（角色位置）
	var desired_pos := target.global_position
	
	# 尝试获取偏移向量
	var offset_vec := Vector2.ZERO
	if offset_factor != 0.0 and not look_ahead_property.is_empty():
		offset_vec = _get_property_vector(target, look_ahead_property).normalized()
		# 应用偏移系数（偏移量 = 向量 * 系数）
		desired_pos += offset_vec * offset_factor
	
	## 快出缓回
	if offset_vec == Vector2.ZERO:
		global_position = lerp(global_position, desired_pos, delta)
	else:
		global_position = global_position.move_toward(desired_pos, follow_speed * delta)
	

## 安全地从目标节点获取指定名称的 Vector2 属性
func _get_property_vector(obj: Object, prop_name: StringName) -> Vector2:
	if obj == null:
		return Vector2.ZERO
	
	var prop_list := obj.get_property_list()
	for prop in prop_list:
		if prop["name"] == prop_name and prop["type"] == TYPE_VECTOR2:
			return obj.get(prop_name) as Vector2
	return Vector2.ZERO

#region ShakeFunc

# 抖动内部状态
var _shake_intensity: float = 0.0
var _shake_duration: float = 0.0
var _shake_elapsed: float = 0.0
## 若不为零向量，则沿此方向（归一化）单向震荡；否则全随机抖动
var _shake_direction: Vector2 = Vector2.ZERO

func _process(delta: float) -> void:
	_update_shake(delta)

## 每帧更新镜头偏移，实现抖动效果
func _update_shake(delta: float) -> void:
	if _shake_duration > 0.0:
		_shake_elapsed += delta
		if _shake_elapsed >= _shake_duration:
			# 抖动结束
			_shake_duration = 0.0
			offset = Vector2.ZERO
		else:
			var progress: float = _shake_elapsed / _shake_duration
			var current_intensity: float = _shake_intensity * (1.0 - progress)
			if _shake_direction != Vector2.ZERO:
				# 方向性抖动：沿方向正负震荡（频率固定，也可按需导出）
				var wave: float = sin(_shake_elapsed * 30.0)
				offset = _shake_direction * wave * current_intensity
			else:
				# 随机抖动
				offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * current_intensity
	else:
		# 确保无抖动时归零
		offset = Vector2.ZERO

## 触发通用镜头抖动
## intensity: 抖动强度（像素偏移量）
## duration: 持续时间（秒）
## direction: 若提供，抖动将沿该方向来回摆动；否则为全方向随机抖动
func start_shake(intensity: float, duration: float, direction: Vector2 = Vector2.ZERO) -> void:
	_shake_intensity = intensity
	_shake_duration = max(duration, 0.0)
	_shake_elapsed = 0.0
	if direction != Vector2.ZERO:
		_shake_direction = direction.normalized()
	else:
		_shake_direction = Vector2.ZERO

## 斩击抖动（方向性，适合配合攻击方向使用）
func slash_shake(intensity: float = 5.0, duration: float = 0.15, direction: Vector2 = Vector2(1.0, 0.0)) -> void:
	start_shake(intensity, duration, direction)

## 受击抖动（无方向，较剧烈）
func hit_shake(intensity: float = 10.0, duration: float = 0.3) -> void:
	start_shake(intensity, duration)

#endregion
