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
## 跟随平滑速度（值越大跟随越快，推荐 3~8）
@export var follow_smooth: float = 5.0

# 内部变量
var _target_zoom: Vector2

func _ready() -> void:
	current = self
	_target_zoom = self.zoom

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
		offset_vec = _get_property_vector(target, look_ahead_property)
		# 应用偏移系数（偏移量 = 向量 * 系数）
		desired_pos += offset_vec * offset_factor
	
	# 使用指数平滑（无抖动，对帧率稳定）
	# 公式：new = current + (target - current) * (1 - exp(-speed * delta))
	var weight := 1.0 - exp(-follow_smooth * delta)
	global_position = global_position.lerp(desired_pos, weight)


## 安全地从目标节点获取指定名称的 Vector2 属性
func _get_property_vector(obj: Object, prop_name: StringName) -> Vector2:
	if obj == null:
		return Vector2.ZERO
	
	var prop_list := obj.get_property_list()
	for prop in prop_list:
		if prop["name"] == prop_name and prop["type"] == TYPE_VECTOR2:
			return obj.get(prop_name) as Vector2
	return Vector2.ZERO
