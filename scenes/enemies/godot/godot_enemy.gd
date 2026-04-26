@tool
class_name GodotEnemy
extends BaseEnemy

#region Visualization
## 扇形射线数量（建议奇数，中间与期望方向对齐）
@export var ray_count: int = 7:
	set(v):
		ray_count = v
		queue_redraw()
## 扇形总开角（度）
@export var ray_spread_degrees: float = 75.0:
	set(v):
		ray_spread_degrees = v
		queue_redraw()
## 射线探测距离（应大于碰撞半径）
@export var ray_distance: float = 50.0:
	set(v):
		ray_distance = v
		queue_redraw()
## 射线碰撞检测层（需与障碍物所在层一致）
@export_flags_2d_physics var obstacle_collision_mask: int = 1:
	set(v):
		obstacle_collision_mask = v
		queue_redraw()
## 运行时是否显示射线和碰撞信息
@export var debug_mode: bool = false
#endregion

## 移动速度（像素/秒）
@export var speed: float = 120.0
## 加速度
@export var acceleration: float = 600.0
## 路径更新间隔（秒）
@export var path_update_interval: float = 1.0
## 判定到达路径点的距离阈值
@export var arrival_threshold: float = 15.0
## 触发脱困的卡墙时间（秒）
@export var stuck_time: float = 3.0
## 判断卡墙的单帧最小移动距离
@export var stuck_distance_threshold: float = 5.0

@export var player: Node2D
var current_path: Array[Vector2] = []
var path_index: int = 1
var time_since_path_update: float = 0.0

# 卡墙脱困相关
var _prev_position: Vector2
var _stuck_timer: float = 0.0
var _stuck_recovery_dir: Vector2 = Vector2.ZERO
var _stuck_recovery_start_pos: Vector2
var _stuck_recovery_time_remaining: float = 0.0

# 调试绘制数据
var _debug_rays: Array = []  # { "dir": Vector2, "hit": bool, "hit_point_world": Vector2, "weight": float }


func _ready() -> void:
	if Engine.is_editor_hint():
		queue_redraw()
		return

	_prev_position = global_position
	if player == null:
		var root = get_tree().current_scene
		if root:
			player = root.get_node_or_null("Player")


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return

	if player == null:
		return

	# 定时更新路径
	time_since_path_update += delta
	if time_since_path_update >= path_update_interval:
		_update_path()
		time_since_path_update = 0.0

	# 确定期望方向（优先跟随路径点）
	var target_dir := Vector2.ZERO
	if current_path.size() > 1 and path_index < current_path.size():
		var target_point: Vector2 = current_path[path_index]
		target_dir = global_position.direction_to(target_point)
		if global_position.distance_to(target_point) < arrival_threshold:
			path_index += 1
			if path_index >= current_path.size():
				current_path.clear()
	else:
		target_dir = global_position.direction_to(player.global_position)

	if target_dir == Vector2.ZERO:
		velocity = velocity.move_toward(Vector2.ZERO, acceleration * delta)
		move_and_slide()
		return

	# 扇形射线检测
	var sweep = _perform_ray_sweep(target_dir)
	_debug_rays = sweep.rays
	var normal_avoid_dir = sweep.weighted_dir
	var free_dirs: Array = sweep.free_dirs

	# 计算上一帧实际移动距离（用于卡墙检测）
	var moved_this_frame := global_position.distance_to(_prev_position)

	# 只有沿路径移动时才检测卡墙
	var is_on_path := current_path.size() > 1 and path_index < current_path.size()

	if is_on_path:
		if moved_this_frame < stuck_distance_threshold:
			_stuck_timer += delta
		else:
			_stuck_timer = 0.0
			# 一旦移动，立即退出脱困模式
			if _stuck_recovery_dir != Vector2.ZERO:
				_stuck_recovery_dir = Vector2.ZERO
	else:
		_stuck_timer = 0.0

	# 脱困模式：强制沿安全方向移动
	if _stuck_recovery_dir != Vector2.ZERO:
		var recovery_dist := global_position.distance_to(_stuck_recovery_start_pos)
		if recovery_dist > 50.0 or _stuck_recovery_time_remaining <= 0.0:
			_stuck_recovery_dir = Vector2.ZERO
			_stuck_timer = 0.0
		else:
			_stuck_recovery_time_remaining -= delta

	# 触发脱困
	if _stuck_recovery_dir == Vector2.ZERO and is_on_path and _stuck_timer >= stuck_time:
		if free_dirs.size() > 0:
			var best_dir = free_dirs[0]
			var best_dot = best_dir.dot(target_dir)
			for d in free_dirs:
				var dot = d.dot(target_dir)
				if dot > best_dot:
					best_dir = d
					best_dot = dot
			_stuck_recovery_dir = best_dir
		else:
			# 所有方向均有碰撞，尝试垂直方向
			_stuck_recovery_dir = normal_avoid_dir.rotated(PI / 2.0)
		_stuck_recovery_start_pos = global_position
		_stuck_recovery_time_remaining = 0.8
		_stuck_timer = 0.0

	# 最终移动方向
	var move_dir = _stuck_recovery_dir if _stuck_recovery_dir != Vector2.ZERO else normal_avoid_dir

	# 应用速度
	var desired_velocity = move_dir * speed
	velocity = velocity.move_toward(desired_velocity, acceleration * delta)
	move_and_slide()

	_prev_position = global_position
	queue_redraw()


func _update_path() -> void:
	if player == null:
		return
	var new_path = Global.Path_Finder.find_path(global_position, player.global_position)
	if new_path.size() > 1:
		current_path = new_path
		path_index = 1
		
		# test
		if Global.draw_path:
			Global.draw_path.draw_path(new_path)
	else:
		current_path.clear()


## 核心扇形射线检测，返回加权避障方向、完全畅通的方向列表及射线数据
func _perform_ray_sweep(desired_dir: Vector2) -> Dictionary:
	var space_state := get_world_2d().direct_space_state
	var spread_rad := deg_to_rad(ray_spread_degrees)
	var half_spread := spread_rad / 2.0
	var base_angle := desired_dir.angle()

	var query := PhysicsRayQueryParameters2D.create(global_position, global_position, obstacle_collision_mask)
	query.exclude = [self]

	var weighted_dir := Vector2.ZERO
	var total_weight := 0.0
	var free_dirs: Array[Vector2] = []
	var ray_data: Array = []

	for i in range(ray_count):
		var offset := 0.0
		if ray_count > 1:
			offset = lerpf(-half_spread, half_spread, float(i) / (ray_count - 1))
		var angle := base_angle + offset
		var dir := Vector2.RIGHT.rotated(angle)
		var end_point := global_position + dir * ray_distance
		query.to = end_point

		var result := space_state.intersect_ray(query)
		var hit := not result.is_empty()
		var hit_point_world := end_point
		var weight := 1.0

		if hit:
			hit_point_world = result.position
			var dist := global_position.distance_to(hit_point_world)
			weight = clamp(dist / ray_distance, 0.0, 1.0)
		else:
			free_dirs.append(dir)

		weighted_dir += dir * weight
		total_weight += weight

		ray_data.append({
			"dir": dir,
			"hit": hit,
			"hit_point_world": hit_point_world,
			"weight": weight
		})

	var final_dir := desired_dir
	if total_weight > 0.001:
		final_dir = weighted_dir.normalized()

	return {
		"weighted_dir": final_dir,
		"free_dirs": free_dirs,
		"rays": ray_data
	}


#region Drawing

func _draw() -> void:
	if Engine.is_editor_hint():
		_draw_editor_visualization()
	elif debug_mode and not _debug_rays.is_empty():
		_draw_runtime_debug()


func _draw_editor_visualization() -> void:
	# 在编辑器中以固定方向（右）显示扇形扫描范围
	var center_dir := Vector2.RIGHT
	var spread_rad := deg_to_rad(ray_spread_degrees)
	var half_spread := spread_rad / 2.0
	var base_angle := center_dir.angle()

	for i in range(ray_count):
		var offset := 0.0
		if ray_count > 1:
			offset = lerpf(-half_spread, half_spread, float(i) / (ray_count - 1))
		var angle := base_angle + offset
		var dir := Vector2.RIGHT.rotated(angle)
		var local_end := dir * ray_distance
		draw_line(Vector2.ZERO, local_end, Color(0.3, 0.8, 1.0, 0.5), 0.8)
	draw_circle(Vector2.ZERO, 3.0, Color.WHITE)  # 中心点


func _draw_runtime_debug() -> void:
	for ray in _debug_rays:
		var local_end := to_local(ray.hit_point_world)
		var color := Color.RED if ray.hit else Color.GREEN
		draw_line(Vector2.ZERO, local_end, color, 1.2)
		if ray.hit:
			draw_circle(local_end, 3.0, Color.WHITE)

#endregion
