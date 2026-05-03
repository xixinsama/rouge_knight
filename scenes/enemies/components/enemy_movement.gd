## 敌怪移动组件 — 在 _physics_process 中驱动父节点 CharacterBody2D 的速度
## 支持五种移动模式：
##   IDLE   — 静止
##   CHASE  — 追击玩家（可选 A* 寻路 + 射线避障 + 卡死恢复）
##   FLEE   — 远离玩家
##   CHARGE — 高速冲向玩家
##   WANDER — 随机闲逛
## 避障使用扇形射线检测，卡死时自动寻找可行方向绕路
extends Node
class_name EnemyMovement

enum Mode { IDLE, CHASE, FLEE, CHARGE, WANDER }

var current_mode: Mode = Mode.IDLE

## 移动速度
@export var move_speed: float = 80.0
## 加速度
@export var acceleration: float = 400.0
## A* 寻路更新间隔（秒）
@export var path_update_interval: float = 0.5
## 到达路径点的判定距离
@export var arrival_threshold: float = 15.0
## 是否使用 A* 寻路（false = 直线追向玩家）
@export var use_pathfinding: bool = true
## 是否有地形限制（false = 可穿墙）
@export var terrain_restricted: bool = true

## 扇形避障射线数量
@export var ray_count: int = 7
## 扇形避障射线散布角度（度）
@export var ray_spread_degrees: float = 75.0
## 避障射线长度
@export var ray_distance: float = 50.0
## 障碍物物理层
@export_flags_2d_physics var obstacle_mask: int = 1

## 卡死判定时间（秒）
@export var stuck_time: float = 1.0
## 卡死判定位移阈值（像素）
@export var stuck_distance_threshold: float = 5.0

var _target: Node2D
var _body: CharacterBody2D
var _current_path: Array[Vector2] = []
var _path_index: int = 1
var _path_timer: float = 0.0
var _prev_position: Vector2
var _stuck_timer: float = 0.0
var _stuck_recovery_dir: Vector2 = Vector2.ZERO
var _stuck_recovery_start_pos: Vector2
var _stuck_recovery_time: float = 0.0
var _wander_target: Vector2
var _wander_wait: float = 0.0


func _ready() -> void:
	_body = get_parent() as CharacterBody2D
	_prev_position = _body.global_position
	set_physics_process(true)


func set_target(target: Node2D) -> void:
	_target = target


func set_mode(mode: Mode) -> void:
	current_mode = mode
	if mode != Mode.CHASE:
		_current_path.clear()


func _physics_process(delta: float) -> void:
	if not _body:
		return

	match current_mode:
		Mode.IDLE:
			_apply_velocity(Vector2.ZERO, delta)
		Mode.CHASE:
			if _target:
				_chase(delta)
			else:
				_apply_velocity(Vector2.ZERO, delta)
		Mode.FLEE:
			if _target:
				_flee(delta)
			else:
				_apply_velocity(Vector2.ZERO, delta)
		Mode.CHARGE:
			if _target:
				_charge(delta)
			else:
				_apply_velocity(Vector2.ZERO, delta)
		Mode.WANDER:
			_wander(delta)

	_prev_position = _body.global_position


## 追击：根据 config 选择 A* 寻路或直线移动
func _chase(delta: float) -> void:
	if use_pathfinding:
		_chase_with_pathfinding(delta)
	else:
		_chase_direct(delta)


## A* 寻路追击：定期向 Global.Path_Finder 请求路径，沿路径点移动
func _chase_with_pathfinding(delta: float) -> void:
	_path_timer += delta
	if _path_timer >= path_update_interval:
		_update_path()
		_path_timer = 0.0

	var target_dir := Vector2.ZERO
	if _current_path.size() > 1 and _path_index < _current_path.size():
		var tp: Vector2 = _current_path[_path_index]
		target_dir = _body.global_position.direction_to(tp)
		if _body.global_position.distance_to(tp) < arrival_threshold:
			_path_index += 1
			if _path_index >= _current_path.size():
				_current_path.clear()
	else:
		# 路径无效时退化为直线追击
		target_dir = _body.global_position.direction_to(_target.global_position)

	if target_dir == Vector2.ZERO:
		_apply_velocity(Vector2.ZERO, delta)
		return

	var move_dir := _avoid_obstacles(target_dir, delta)
	_apply_velocity(move_dir * move_speed, delta)


## 直线追击（无视地形或寻路关闭时）
func _chase_direct(delta: float) -> void:
	var dir := _body.global_position.direction_to(_target.global_position)
	if terrain_restricted:
		dir = _avoid_obstacles(dir, delta)
	_apply_velocity(dir * move_speed, delta)


## 逃离玩家
func _flee(delta: float) -> void:
	var dir := _target.global_position.direction_to(_body.global_position)
	_apply_velocity(dir * move_speed, delta)


## 高速冲锋
func _charge(delta: float) -> void:
	var dir := _body.global_position.direction_to(_target.global_position)
	_apply_velocity(dir * move_speed * 2.0, delta)


## 随机闲逛：到达 wander_target 后随机等待 0.5~2 秒，再选新目标
func _wander(delta: float) -> void:
	if _wander_wait > 0:
		_wander_wait -= delta
		_apply_velocity(Vector2.ZERO, delta)
		return

	if _wander_target == Vector2.ZERO or _body.global_position.distance_to(_wander_target) < arrival_threshold:
		_wander_wait = randf_range(0.5, 2.0)
		_wander_target = _body.global_position + Vector2(randf_range(-100, 100), randf_range(-100, 100))
		return

	var dir := _body.global_position.direction_to(_wander_target)
	_apply_velocity(dir * move_speed * 0.5, delta)


## 扇形射线避障：在 desired_dir 两侧 spread_degrees 范围内发射 ray_count 条射线，
## 按每条射线的可达距离加权平均得到最终移动方向
func _avoid_obstacles(desired_dir: Vector2, delta: float) -> Vector2:
	var spread_rad := deg_to_rad(ray_spread_degrees)
	var half_spread := spread_rad / 2.0
	var base_angle := desired_dir.angle()
	var space_state := _body.get_world_2d().direct_space_state

	var weighted_dir := Vector2.ZERO
	var total_weight := 0.0
	var free_dirs: Array[Vector2] = []

	for i in range(ray_count):
		var offset := 0.0
		if ray_count > 1:
			offset = lerpf(-half_spread, half_spread, float(i) / (ray_count - 1))
		var angle := base_angle + offset
		var ray_dir := Vector2.RIGHT.rotated(angle)
		var end := _body.global_position + ray_dir * ray_distance

		var query := PhysicsRayQueryParameters2D.create(_body.global_position, end, obstacle_mask)
		query.exclude = [_body]
		var result := space_state.intersect_ray(query)

		var weight := 1.0
		if not result.is_empty():
			var dist := _body.global_position.distance_to(result.position)
			weight = clamp(dist / ray_distance, 0.0, 1.0)
		else:
			free_dirs.append(ray_dir)

		weighted_dir += ray_dir * weight
		total_weight += weight

	if total_weight > 0.001:
		weighted_dir = weighted_dir.normalized()
	else:
		weighted_dir = desired_dir

	if terrain_restricted:
		_check_stuck(desired_dir, free_dirs, delta)
		if _stuck_recovery_dir != Vector2.ZERO:
			return _stuck_recovery_dir

	return weighted_dir


## 卡死检测与恢复：当位移低于阈值超过 stuck_time 时，
## 从无障碍方向中选一个最接近 desired_dir 的作为恢复方向
func _check_stuck(desired_dir: Vector2, free_dirs: Array, delta: float) -> void:
	var moved := _body.global_position.distance_to(_prev_position)

	if _stuck_recovery_dir != Vector2.ZERO:
		if _body.global_position.distance_to(_stuck_recovery_start_pos) > 50.0 or _stuck_recovery_time <= 0.0:
			_stuck_recovery_dir = Vector2.ZERO
			_stuck_timer = 0.0
		else:
			_stuck_recovery_time -= delta
		return

	if moved < stuck_distance_threshold:
		_stuck_timer += delta
	else:
		_stuck_timer = 0.0

	if _stuck_timer >= stuck_time:
		if free_dirs.size() > 0:
			var best: Vector2 = free_dirs[0]
			var best_dot: float = best.dot(desired_dir)
			for d in free_dirs:
				var dot: float = d.dot(desired_dir)
				if dot > best_dot:
					best = d
					best_dot = dot
			_stuck_recovery_dir = best
		else:
			_stuck_recovery_dir = desired_dir.rotated(PI / 2.0)
		_stuck_recovery_start_pos = _body.global_position
		_stuck_recovery_time = 0.8
		_stuck_timer = 0.0


func _apply_velocity(desired_velocity: Vector2, delta: float) -> void:
	_body.velocity = _body.velocity.move_toward(desired_velocity, acceleration * delta)
	_body.move_and_slide()


## 向 Global.Path_Finder 请求当前层的最短路径
func _update_path() -> void:
	if not Global.Path_Finder or not _target:
		return
	var new_path := Global.Path_Finder.find_path(_body.global_position, _target.global_position)
	if new_path.size() > 1:
		_current_path = new_path
		_path_index = 1
	else:
		_current_path.clear()
