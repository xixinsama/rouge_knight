@tool
## 矩形传送区域组件
## 如果一个节点（或场景）在多个该组件上被注册，最后会呈现出只有最后一个执行的该组件生效
## 所以最好一个节点（或场景）只在一个该组件上注册
## 使用方法：
## 注册：register(node: Node2D)
## 取消注册：unregister(node: Node2D)
class_name DonutArea2D
extends Node2D

## 矩形区域的尺寸（局部坐标，从 (0,0) 开始），编辑器里会绘制边框。
## 运行时所有注册的 Node2D 将被限制在该矩形内外，行为取决于 boundary_mode。
@export var rect_size := Vector2(200, 200):
	set(value):
		rect_size = value
		queue_redraw()

enum BoundaryMode {
	NoEntryNoExit = 0,   ## 不准进不准出（内外各自循环）
	EntryOnly    = 1,    ## 准进不准出（外部可进入内部，内部不出）
	ExitOnly     = 2,    ## 准出不准进（内部可出去外部，外部不进）
	Disabled     = 3     ## 准进准出（失效，无传送效果）
}
## 边界模式：
@export var boundary_mode: BoundaryMode = BoundaryMode.NoEntryNoExit:
	set(value):
		boundary_mode = value
		queue_redraw()

## Physics：每物理帧 _physics_process 中执行。
enum UpdateType {
	Idle = 0,    ## Idle：每帧 _process 中执行
	Physics = 1  ## Physics：每物理帧 _physics_process 中执行
}
## 传送逻辑的执行时机。
@export var update_mode: UpdateType = UpdateType.Idle:
	set(value):
		update_mode = value
		if not Engine.is_editor_hint():
			_apply_update_mode()

## 若为 true，游戏运行时也会绘制矩形边框及填充（用于调试）。
@export var debug_draw_runtime := false:
	set(value):
		debug_draw_runtime = value
		queue_redraw()

# 存储已注册节点的 instance_id，用 id 保证唯一且安全清理
var _registered_ids: Array[int] = []
# 存储已注册节点上一帧的相对坐标
var _node_was_inside: Dictionary[int, Vector2] = {}

func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_apply_update_mode()


func _apply_update_mode() -> void:
	set_process(false)
	set_physics_process(false)
	match update_mode:
		0: set_process(true)
		1: set_physics_process(true)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	if update_mode == 0:
		_update_warp()


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	
	if update_mode == 1:
		_update_warp()


func _update_warp() -> void:
	var rect := Rect2(global_position, rect_size)
	var size := rect_size

	for id in _registered_ids.duplicate():
		var node: Node2D = instance_from_id(id) as Node2D
		if not is_instance_valid(node) or not node.is_inside_tree():
			_remove_id(id)
			continue

		var pos := node.global_position
		var rel := pos - rect.position

		# 取出上一帧的相对坐标（首次用当前值，避免误判）
		var prev_rel: Vector2 = _node_was_inside.get(id, rel)
		var was_inside := (prev_rel.x >= 0.0 and prev_rel.x < size.x and
						   prev_rel.y >= 0.0 and prev_rel.y < size.y)
		var is_inside := (rel.x >= 0.0 and rel.x < size.x and
						  rel.y >= 0.0 and rel.y < size.y)

		match boundary_mode:
			0:  # 不准进不准出：所有节点强制限制在矩形内循环
				rel.x = fposmod(rel.x, size.x)
				rel.y = fposmod(rel.y, size.y)

			1:  # 准进不准出：内部节点循环，外部自由进入；内部不能出去
				if was_inside and not is_inside:
					# 上一帧在内部，现在在外部 → 刚刚越界，强制传送回内部
					rel.x = fposmod(rel.x, size.x)
					rel.y = fposmod(rel.y, size.y)
				# 否则：不做处理

			2:  # 准出不准进：外部节点自由离开，外部不能进来
				if not was_inside and is_inside:
					# 刚从外部进入内部
					# 处理 X 轴穿越
					if prev_rel.x < 0.0 and rel.x >= 0.0:
						# 从左边进入 → 传送到右边外部
						rel.x = size.x + fmod(rel.x, size.x)
					elif prev_rel.x >= size.x and rel.x < size.x:
						# 从右边进入 → 传送到左边外部
						rel.x = fmod(rel.x, size.x) - size.x
					# 否则 X 方向未穿越，rel.x 保持不变

					# 处理 Y 轴穿越
					if prev_rel.y < 0.0 and rel.y >= 0.0:
						# 从上边进入 → 传送到下边外部
						rel.y = size.y + fmod(rel.y, size.y)
					elif prev_rel.y >= size.y and rel.y < size.y:
						# 从下边进入 → 传送到上边外部
						rel.y = fmod(rel.y, size.y) - size.y
					# 否则 Y 方向未穿越，rel.y 保持不变
				# 其他情况（一直在外、一直在内、从内到外）不做处理

			3:  # 失效模式
				pass

		var new_pos := rect.position + rel
		if new_pos != pos:
			node.global_position = new_pos

		# 更新记录：保存最终位置的相对坐标
		_node_was_inside[id] = new_pos - rect.position


func _draw() -> void:
	if not (Engine.is_editor_hint() or debug_draw_runtime):
		return

	var r := Rect2(Vector2.ZERO, rect_size)
	# 根据模式选择颜色
	var col: Color
	match boundary_mode:
		0: col = Color(1.0, 0.2, 0.2, 0.8)  # 红
		1: col = Color(1.0, 0.8, 0.2, 0.8)  # 黄
		2: col = Color(0.2, 0.4, 1.0, 0.8)  # 蓝
		3: col = Color(0.6, 0.6, 0.6, 0.5)  # 灰

	draw_rect(r, col, false, 2.0)
	draw_rect(r, Color(col, 0.15), true)


## 注册一个 Node2D 节点，使其被此区域管理。
## 当节点离开场景树时，会自动注销，无需手动调用。
func register(node: Node2D) -> void:
	if not is_instance_valid(node):
		push_error("DonutArea2D: 无法注册无效的节点。")
		return

	var id := node.get_instance_id()
	if id in _registered_ids:
		return

	if not node.tree_exited.is_connected(_on_node_tree_exited.bind(id)):
		node.tree_exited.connect(_on_node_tree_exited.bind(id), CONNECT_ONE_SHOT)

	_registered_ids.append(id)


## 手动注销一个节点，立刻停止对其的位置约束。
func unregister(node: Node2D) -> void:
	if not is_instance_valid(node):
		_clean_invalid_ids()
		return
	_remove_id(node.get_instance_id())


## 内部：根据 id 移除注册记录
func _remove_id(id: int) -> void:
	_registered_ids.erase(id)
	_node_was_inside.erase(id)


## 内部：信号回调，节点离开树时自动移除
func _on_node_tree_exited(id: int) -> void:
	_remove_id(id)


## 清理所有已失效的 id（节点被释放而未触发 tree_exited 的情况）
func _clean_invalid_ids() -> void:
	var i := _registered_ids.size() - 1
	while i >= 0:
		var id := _registered_ids[i]
		if not is_instance_valid(instance_from_id(id)):
			_registered_ids.remove_at(i)
		i -= 1


func _exit_tree() -> void:
	_registered_ids.clear()
	_node_was_inside.clear()
