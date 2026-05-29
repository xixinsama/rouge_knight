## DonutArea2D 性能测试
##
## 用法：直接运行 res://tests/donut_test/donut_perf_test.tscn
## 特性：
##   - 默认生成 1000 个节点，在矩形区域内随机移动
##   - 测量 _update_warp() 每帧的耗时（avg / max / min）
##   - 实时显示 FPS、warp 耗时、节点数、越界数量
##   - 可切换边界模式、调整节点数量、自动跑分
##
## 性能目标（1000 节点）：
##   < 1.0 ms : 优秀
##   1-2 ms   : 良好
##   2-5 ms   : 一般
##   > 5 ms   : 需优化
extends Control

const DEFAULT_NODE_COUNT := 1000
const RECT_SIZE := Vector2(400, 400)
const SAMPLE_WINDOW := 120

# 测试基础设施
var _donut: DonutArea2D
var _outbox_donut: DonutArea2D

var _test_nodes: Array[Node2D] = []
var _warp_times: Array[float] = []
var _frame_times: Array[float] = []
var _violations := 0
var _enabled := false

# UI
var _fps_label: Label
var _warp_label: Label
var _frame_label: Label
var _count_label: Label
var _mode_label: Label
var _violation_label: Label
var _summary_label: Label
var _toggle_btn: Button
var _mode_btn: Button
var _count_input: LineEdit
var _bench_btn: Button

# 自动跑分状态
var _benchmarking := false
var _bench_mode_idx := 0
var _bench_timer := 0.0
var _bench_results: Array[Dictionary] = []
const BENCH_DURATION := 3.0  # 每种模式跑 3 秒


func _ready() -> void:
	_setup_donut()
	_setup_ui()
	_spawn_nodes(DEFAULT_NODE_COUNT)
	_register_all()


func _setup_donut() -> void:
	_donut = DonutArea2D.new()
	_donut.position = (get_viewport_rect().size - RECT_SIZE) / 2.0
	_donut.rect_size = RECT_SIZE
	_donut.boundary_mode = DonutArea2D.BoundaryMode.NoEntryNoExit
	_donut.update_mode = DonutArea2D.UpdateType.Physics
	_donut.debug_draw_runtime = true
	add_child(_donut)
	# 禁用内置自动处理，由本测试脚本手动调用 _update_warp 来精确测量
	_donut.set_process(false)
	_donut.set_physics_process(false)
	
	_outbox_donut = DonutArea2D.new()
	_outbox_donut.position = (get_viewport_rect().size - 1.6 * RECT_SIZE) / 2.0
	_outbox_donut.rect_size = 1.6 * RECT_SIZE
	_outbox_donut.boundary_mode = DonutArea2D.BoundaryMode.NoEntryNoExit
	_outbox_donut.update_mode = DonutArea2D.UpdateType.Physics
	_outbox_donut.debug_draw_runtime = true
	add_child(_outbox_donut)


func _setup_ui() -> void:
	var vbox := VBoxContainer.new()
	vbox.position = Vector2(16, 16)
	vbox.add_theme_constant_override("separation", 2)
	add_child(vbox)

	_fps_label = _make_label("FPS: --")
	vbox.add_child(_fps_label)

	_warp_label = _make_label("Warp: --")
	vbox.add_child(_warp_label)

	_frame_label = _make_label("Frame: --")
	vbox.add_child(_frame_label)

	_count_label = _make_label("Nodes: 0")
	vbox.add_child(_count_label)

	_mode_label = _make_label("Mode: --")
	vbox.add_child(_mode_label)

	_violation_label = _make_label("Violations: 0")
	vbox.add_child(_violation_label)

	_summary_label = _make_label("")
	vbox.add_child(_summary_label)

	vbox.add_child(_make_label(""))  # spacer

	_toggle_btn = Button.new()
	_toggle_btn.text = "Start Test"
	_toggle_btn.pressed.connect(_on_toggle)
	vbox.add_child(_toggle_btn)

	_mode_btn = Button.new()
	_mode_btn.text = "Cycle Mode"
	_mode_btn.pressed.connect(_on_cycle_mode)
	vbox.add_child(_mode_btn)

	var hbox := HBoxContainer.new()
	vbox.add_child(hbox)
	_count_input = LineEdit.new()
	_count_input.text = str(DEFAULT_NODE_COUNT)
	_count_input.custom_minimum_size.x = 80
	hbox.add_child(_count_input)
	var apply_btn := Button.new()
	apply_btn.text = "Set Count"
	apply_btn.pressed.connect(_on_set_count)
	hbox.add_child(apply_btn)

	_bench_btn = Button.new()
	_bench_btn.text = "Auto-Benchmark (4 modes × 3s)"
	_bench_btn.pressed.connect(_on_start_benchmark)
	vbox.add_child(_bench_btn)

	var quit_btn := Button.new()
	quit_btn.text = "Quit"
	quit_btn.pressed.connect(func(): get_tree().quit())
	vbox.add_child(quit_btn)


func _make_label(text: String) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", 15)
	return lbl


func _spawn_nodes(count: int) -> void:
	_clear_nodes()
	var rng := RandomNumberGenerator.new()
	rng.seed = 42

	for i in count:
		var node := Node2D.new()
		node.position = Vector2(
			rng.randf_range(0, RECT_SIZE.x),
			rng.randf_range(0, RECT_SIZE.y))
		var angle := rng.randf_range(0, TAU)
		var speed := rng.randf_range(80.0, 350.0)
		node.set_meta(&"velocity", Vector2.RIGHT.rotated(angle) * speed)

		# 小型可视化标记
		var rect := ColorRect.new()
		rect.size = Vector2(3, 3)
		rect.color = Color(1, 1, 1, 0.65)
		rect.position = -rect.size / 2.0
		node.add_child(rect)

		_donut.add_child(node)
		_test_nodes.append(node)


func _clear_nodes() -> void:
	for node in _test_nodes:
		if is_instance_valid(node):
			_donut.unregister(node)
			_outbox_donut.unregister(node)
			node.queue_free()
	_test_nodes.clear()


func _register_all() -> void:
	for node in _test_nodes:
		_donut.register(node)
		_outbox_donut.register(node)


func _move_nodes(delta: float) -> void:
	for node in _test_nodes:
		if not is_instance_valid(node):
			continue
		var vel: Vector2 = node.get_meta(&"velocity", Vector2.ZERO)
		node.position += vel * delta


func _count_violations() -> int:
	# NoEntryNoExit 模式下，所有节点都应被约束在矩形内
	if _donut.boundary_mode != DonutArea2D.BoundaryMode.NoEntryNoExit:
		return -1
	var v_size = RECT_SIZE
	var violations := 0
	for node in _test_nodes:
		if not is_instance_valid(node):
			continue
		var p := node.position
		if p.x < -0.1 or p.x > v_size.x + 0.1 or p.y < -0.1 or p.y > v_size.y + 0.1:
			violations += 1
	return violations


func _process(delta: float) -> void:
	if _benchmarking:
		_benchmark_process(delta)
		return

	if not _enabled:
		_update_labels()
		return

	_move_nodes(delta)

	var start := Time.get_ticks_usec()
	_donut._update_warp()
	var elapsed := (Time.get_ticks_usec() - start) / 1000.0

	_warp_times.append(elapsed)
	if _warp_times.size() > SAMPLE_WINDOW:
		_warp_times.pop_front()

	_frame_times.append(delta * 1000.0)
	if _frame_times.size() > SAMPLE_WINDOW:
		_frame_times.pop_front()

	_violations = _count_violations()
	_update_labels()


func _update_labels() -> void:
	_fps_label.text = "FPS: %d" % Engine.get_frames_per_second()

	if _warp_times.is_empty():
		_warp_label.text = "Warp: --"
	else:
		var avg := _avg(_warp_times)
		var mx = _warp_times.max()
		var mn = _warp_times.min()
		_warp_label.text = "Warp  avg: %.3f  max: %.3f  min: %.3f ms" % [avg, mx, mn]

	if _frame_times.is_empty():
		_frame_label.text = "Frame: --"
	else:
		_frame_label.text = "Frame avg: %.2f ms" % _avg(_frame_times)

	var active := 0
	for node in _test_nodes:
		if is_instance_valid(node):
			active += 1
	_count_label.text = "Nodes: %d / %d" % [active, _test_nodes.size()]

	var mode_names := ["NoEntryNoExit", "EntryOnly", "ExitOnly", "Disabled"]
	_mode_label.text = "Mode: %s" % mode_names[_donut.boundary_mode]

	if _violations >= 0:
		_violation_label.text = "Violations: %d" % _violations
		if _violations > 0:
			_violation_label.add_theme_color_override("font_color", Color.RED)
		else:
			_violation_label.add_theme_color_override("font_color", Color.GREEN)

	if _warp_times.size() >= 30:
		var avg := _avg(_warp_times)
		var health: String
		var health_color: Color
		if avg < 1.0:
			health = "EXCELLENT (<1ms)"
			health_color = Color.GREEN
		elif avg < 2.0:
			health = "GOOD (1-2ms)"
			health_color = Color.GREEN_YELLOW
		elif avg < 5.0:
			health = "OK (2-5ms)"
			health_color = Color.ORANGE
		else:
			health = "SLOW (>5ms)"
			health_color = Color.RED
		_summary_label.text = "Health: %s  |  %d samples" % [health, _warp_times.size()]
		_summary_label.add_theme_color_override("font_color", health_color)


# ---------- 自动跑分 ----------

func _on_start_benchmark() -> void:
	_benchmarking = true
	_bench_mode_idx = 0
	_bench_timer = 0.0
	_bench_results.clear()
	_bench_btn.disabled = true
	_toggle_btn.disabled = true
	_enabled = true
	_warp_times.clear()
	_frame_times.clear()
	# 从 NoEntryNoExit 开始
	_donut.boundary_mode = DonutArea2D.BoundaryMode.NoEntryNoExit


func _benchmark_process(delta: float) -> void:
	_bench_timer += delta

	_move_nodes(delta)
	var start := Time.get_ticks_usec()
	_donut._update_warp()
	var elapsed := (Time.get_ticks_usec() - start) / 1000.0
	_warp_times.append(elapsed)

	if _bench_timer >= BENCH_DURATION:
		# 记录当前模式结果
		var mode_names := ["NoEntryNoExit", "EntryOnly", "ExitOnly", "Disabled"]
		_bench_results.append({
			mode = mode_names[_donut.boundary_mode],
			avg = _avg(_warp_times),
			max = _warp_times.max(),
			min = _warp_times.min(),
			violations = _count_violations(),
		})

		# 切换到下一模式
		_bench_mode_idx += 1
		if _bench_mode_idx >= 4:
			_benchmarking = false
			_bench_btn.disabled = false
			_toggle_btn.disabled = false
			_donut.boundary_mode = DonutArea2D.BoundaryMode.NoEntryNoExit
			_print_bench_results()
			return

		_donut.boundary_mode = _bench_mode_idx as DonutArea2D.BoundaryMode
		_bench_timer = 0.0
		_warp_times.clear()

	_update_labels()
	_bench_btn.text = "Benchmarking [%d/4] %.1fs" % [_bench_mode_idx + 1, BENCH_DURATION - _bench_timer]


func _print_bench_results() -> void:
	print("=".repeat(50))
	print("  DonutArea2D Performance Benchmark (%d nodes)" % _test_nodes.size())
	print("=".repeat(50))
	for r in _bench_results:
		print("  %-14s  avg: %7.3f ms  max: %7.3f ms  min: %7.3f ms  violations: %s" % [
			r.mode, r.avg, r.max, r.min, str(r.violations)])
	print("=".repeat(50))
	var overall_avg := 0.0
	for r in _bench_results:
		overall_avg += r.avg
	overall_avg /= maxi(_bench_results.size(), 1)
	print("  Overall avg: %.3f ms" % overall_avg)
	print("=".repeat(50))


# ---------- helpers ----------

func _avg(arr: Array[float]) -> float:
	if arr.is_empty():
		return 0.0
	var sum := 0.0
	for v in arr:
		sum += v
	return sum / arr.size()


# ---------- button callbacks ----------

func _on_toggle() -> void:
	_enabled = not _enabled
	_toggle_btn.text = "Stop Test" if _enabled else "Start Test"
	if _enabled:
		_warp_times.clear()
		_frame_times.clear()
		_violations = 0


func _on_cycle_mode() -> void:
	_donut.boundary_mode = ((_donut.boundary_mode + 1) % 4) as DonutArea2D.BoundaryMode
	_warp_times.clear()
	_violations = 0


func _on_set_count() -> void:
	var new_count := int(_count_input.text)
	if new_count < 1 or new_count > 99999:
		return
	_spawn_nodes(new_count)
	_register_all()
	_warp_times.clear()
	_frame_times.clear()


func _exit_tree() -> void:
	_clear_nodes()
