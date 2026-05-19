@tool
extends RefCounted
class_name MazeGenerator

# width, height: 迷宫尺寸
# rng: 随机数生成器
# widen_max_iter: 道路加宽最大迭代次数（默认 2，设为 0 则不加宽）
# keep_dead_end_ratio: 保留死胡同的比例（0.0 ~ 1.0，默认 0.0 即全部消除）
static func generate(width: int, height: int, rng: RandomNumberGenerator,
					widen_max_iter: int = 2,
					keep_dead_end_ratio: float = 0.0) -> Array:
	# ---------- 基础迷宫生成（原有逻辑，道路宽度 = 1） ----------
	var maze = []
	for y in range(height):
		maze.append([])
		for x in range(width):
			maze[y].append(1)

	var stack = [Vector2i(1, 1)]
	maze[1][1] = 0

	var dirs = [
		Vector2i(2, 0), Vector2i(-2, 0),
		Vector2i(0, 2), Vector2i(0, -2)
	]

	while stack.size() > 0:
		var current = stack[-1]
		var neighbors = []
		for d in dirs:
			var nx = current.x + d.x
			var ny = current.y + d.y
			if nx > 0 and nx < width - 1 and ny > 0 and ny < height - 1:
				if maze[ny][nx] == 1:
					neighbors.append(Vector2i(nx, ny))

		if neighbors.size() > 0:
			var next = neighbors[rng.randi() % neighbors.size()]
			var wall_x = (current.x + next.x) / 2
			var wall_y = (current.y + next.y) / 2
			maze[wall_y][wall_x] = 0
			maze[next.y][next.x] = 0
			stack.append(next)
		else:
			stack.pop_back()

	# ---------- 死胡同填充（保留指定比例的过道） ----------
	_remove_dead_ends(maze, rng, keep_dead_end_ratio)

	# ---------- 道路加宽（保证墙厚 ≥1） ----------
	if widen_max_iter > 0:
		_widen_paths_safe(maze, rng, widen_max_iter)

	return maze


# 移除死胡同，但按 keep_ratio 概率保留一部分
static func _remove_dead_ends(maze: Array, rng: RandomNumberGenerator, keep_ratio: float) -> void:
	var height = maze.size()
	var width = maze[0].size()
	var changed = true
	while changed:
		changed = false
		for y in range(1, height - 1):
			for x in range(1, width - 1):
				if maze[y][x] == 0:
					var road_count = 0
					for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
						if maze[y + dd.y][x + dd.x] == 0:
							road_count += 1
					if road_count == 1:
						# 根据保留比例决定是否填充
						if rng.randf() >= keep_ratio:
							maze[y][x] = 1
							changed = true


# 安全加宽：道路变宽 2~3 格，同时保证墙壁厚度始终 ≥ 1
static func _widen_paths_safe(maze: Array, rng: RandomNumberGenerator, max_iter: int) -> void:
	var height = maze.size()
	var width = maze[0].size()

	for _iter in range(max_iter):
		var to_road: Array[Vector2i] = []
		for y in range(1, height - 1):
			for x in range(1, width - 1):
				if maze[y][x] != 1:
					continue
				var road_nbrs = 0
				for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					if maze[y + dd.y][x + dd.x] == 0:
						road_nbrs += 1
				# 只有当周围有 3~4 条道路时才考虑转换为道路
				if road_nbrs >= 3 and road_nbrs <= 4:
					# 安全检测：如果把这个墙变成路，会不会让某个墙格子失去所有墙邻居？
					if _can_safely_convert(maze, x, y):
						to_road.append(Vector2i(x, y))

		# 为增加随机性，只转换一部分候选格子（例如 60%）
		for cell in to_road:
			if rng.randf() < 0.6:
				maze[cell.y][cell.x] = 0


# 判断将 (x, y) 处的墙变为路后，是否仍保证所有墙格至少有 1 个墙邻居（厚度 ≥1）
static func _can_safely_convert(maze: Array, x: int, y: int) -> bool:
	var height = maze.size()
	var width = maze[0].size()
	# 临时变为道路
	maze[y][x] = 0

	# 检查所有受到影响的邻居
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var nx = x + dx
			var ny = y + dy
			if nx < 0 or nx >= width or ny < 0 or ny >= height:
				continue
			if maze[ny][nx] == 1:
				# 至少需要一个墙邻居
				var wall_nbr = 0
				for dd in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var wx = nx + dd.x
					var wy = ny + dd.y
					if wx < 0 or wx >= width or wy < 0 or wy >= height:
						continue
					if maze[wy][wx] == 1:
						wall_nbr += 1
				if wall_nbr == 0:
					# 回滚
					maze[y][x] = 1
					return false

	# 通过检测，回滚（实际修改会在调用方进行）
	maze[y][x] = 1
	return true
