## 随机房间配置生成器
## 用于批量创建 RoomConfig 实例，所有属性均会随机填充。
@tool
class_name RoomConfigGenerator
extends RefCounted

## 生成单个随机的房间配置
##
## [param id] 可指定房间ID，留空则自动生成 "room_xxxx"
## [param size_range] 房间大小的随机范围 [min, max]（包含两端）
## [param wall_thickness] 边框墙壁厚度，1 代表最外层一圈墙
## [param floor_types] 内部地板的可能类型，默认只有 FLOOR
## [param wall_types] 边框墙壁的可能类型，默认只有 WALL_NORMAL
## [param allowed_floors_pool] 允许出现的层数池，从中随机选1~3个
## [param weight_range] 权重的随机范围
## [param connection_range] 允许连接数的随机范围
static func generate_one(
	id: String = "",
	size_range: Vector2i = Vector2i(5, 5),
	max_size: Vector2i = Vector2i(15, 12),
	wall_thickness: int = 1,
	floor_types: Array = [DungeonGrid.CellType.CELL_FLOOR],
	wall_types: Array = [DungeonGrid.CellType.CELL_WALL_NORMAL],
	allowed_floors_pool: Array = [0, 1, 2],
	weight_range: Vector2 = Vector2(0.5, 2.0),
	connection_range: Vector2i = Vector2i(1, 4)
) -> RoomConfig:
	var rng = RandomNumberGenerator.new()
	rng.randomize()

	var cfg = RoomConfig.new()

	# 随机大小
	var w = rng.randi_range(size_range.x, max_size.x)
	var h = rng.randi_range(size_range.y, max_size.y)
	cfg.room_size = Vector2i(w, h)

	# 生成 cells 数组（一维，行优先：index = y * w + x）
	cfg.cells.resize(w * h)
	for y in range(h):
		for x in range(w):
			var is_border = false
			for t in range(wall_thickness):
				if x == t or y == t or x == w - 1 - t or y == h - 1 - t:
					is_border = true
					break
			if is_border:
				cfg.cells[y * w + x] = wall_types[rng.randi() % wall_types.size()]
			else:
				cfg.cells[y * w + x] = floor_types[rng.randi() % floor_types.size()]

	# 房间ID
	if id.is_empty():
		cfg.room_id = "room_%04d" % rng.randi_range(0, 9999)
	else:
		cfg.room_id = id

	# 允许出现的层数：从池中随机选取1~3个不重复
	#var floor_pool: Array = allowed_floors_pool.duplicate()
	#floor_pool.shuffle()
	#var take_count = rng.randi_range(1, min(3, floor_pool.size()))
	cfg.allowed_floor.resize(1)
	cfg.allowed_floor[0] = 0 #floor_pool.slice(0, take_count)

	# 权重
	cfg.weight = rng.randf_range(weight_range.x, weight_range.y)

	# 允许连接数
	cfg.allowed_connections = rng.randi_range(connection_range.x, connection_range.y)

	return cfg


## 批量生成随机房间配置
##
## [param count] 需要生成的数量
## 其余参数与 [method generate_one] 相同
static func generate_batch(
	count: int,
	size_range: Vector2i = Vector2i(5, 5),
	max_size: Vector2i = Vector2i(15, 12),
	wall_thickness: int = 1,
	floor_types: Array = [DungeonGrid.CellType.CELL_FLOOR],
	wall_types: Array = [DungeonGrid.CellType.CELL_WALL_NORMAL],
	allowed_floors_pool: Array = [0, 1, 2],
	weight_range: Vector2 = Vector2(0.5, 2.0),
	connection_range: Vector2i = Vector2i(1, 4)
) -> Array[RoomConfig]:
	var result: Array[RoomConfig] = []
	for i in range(count):
		var cfg = generate_one(
			"", size_range, max_size, wall_thickness,
			floor_types, wall_types, allowed_floors_pool,
			weight_range, connection_range
		)
		result.append(cfg)
	return result
