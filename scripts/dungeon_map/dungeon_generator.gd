## DungeonGenerator — 与现有场景系统的桥接器
## 作为 TileMapLayer 的子节点，连接新的地牢生成系统
extends Node
class_name DungeonGenerator

## 关联的 TileMapLayer
@export var tile_map_layer: TileMapLayer
## 该层的索引 (0/1/2)
@export var level_index: int = 0
## 生成数据
@export var dungeon_config: DungeonConfig
## 本层 salt
@export var layer_salt: Variant = "这是第一层的加盐"

var _layer_rng: RandomNumberGenerator

# ---------- 私有状态 ----------
var _occupancy: Array = []           ## 二维数组，-1 空闲，>=0 为已放置房间索引
var _placed_rooms: Array[DungeonData] = []   ## 已放置的所有房间数据
var _tries_per_room: int = 100       ## 每个房间尝试放置的次数

func _ready() -> void:
	if not tile_map_layer:
		printerr("无关联的TileMapLayer")
	if dungeon_config == null:
		printerr("无DungeonConfig")
	
	dungeon_config.rooms = RoomConfigGenerator.generate_batch(
		30,
		Vector2i(5, 5),
		Vector2i(15, 12),
		1,
		[DungeonGrid.CellType.CELL_FLOOR],
		[DungeonGrid.CellType.CELL_WALL_NORMAL],
		[0],
		Vector2(0.5, 1),
		Vector2i(1, 3)
	)
	
	_layer_rng = SeedManager.get_rng(layer_salt)
	
	place_room()

## 放置一个房间，成功返回 true，并将房间数据存入 dungeon_data
## 可多次调用，每次放置一个不重叠的房间
func place_room() -> bool:
	if dungeon_config.rooms.is_empty():
		return false

	# 初始化占用网格（仅第一次调用执行）
	if _occupancy.is_empty():
		_init_occupancy()

	# 按权重随机选择一个房间配置
	var chosen: RoomConfig = _pick_weighted_room()
	if chosen == null:
		return false

	# 随机旋转（0~3）
	var rot = _layer_rng.randi_range(0, 3)
	var size := chosen.room_size
	# 旋转90°或270°时宽高互换
	if rot == 1 or rot == 3:
		size = Vector2i(size.y, size.x)

	# 房间超出地图则放弃
	if size.x > dungeon_config.dungeon_size.x or size.y > dungeon_config.dungeon_size.y:
		return false

	# 尝试寻找不重叠的位置
	var max_x = dungeon_config.dungeon_size.x - size.x
	var max_y = dungeon_config.dungeon_size.y - size.y
	var pos: Vector2i
	var placed := false
	for _attempt in range(_tries_per_room):
		var x = _layer_rng.randi_range(0, max_x)
		var y = _layer_rng.randi_range(0, max_y)
		if _is_area_free(x, y, size):
			pos = Vector2i(x, y)
			placed = true
			break

	if not placed:
		return false

	# 占用该区域
	_occupy_area(pos, size, _placed_rooms.size())

	# 创建并存储 DungeonData
	var data := DungeonData.new()
	data.room_config = chosen
	data.room_position = pos
	data.room_rotate = rot
	_placed_rooms.append(data)
	return true

# ---------- 辅助方法 ----------

## 按权重随机选取一个 RoomConfig
func _pick_weighted_room() -> RoomConfig:
	var total_weight := 0.0
	for cfg in dungeon_config.rooms:
		total_weight += cfg.weight
	if total_weight <= 0:
		return null

	var r = _layer_rng.randf() * total_weight
	var accum := 0.0
	for cfg in dungeon_config.rooms:
		accum += cfg.weight
		if r <= accum:
			return cfg
	return dungeon_config.rooms[-1]  # 兜底

## 初始化占用网格
func _init_occupancy() -> void:
	var w = dungeon_config.dungeon_size.x
	var h = dungeon_config.dungeon_size.y
	_occupancy.clear()
	for x in range(w):
		var col: Array[int] = []
		col.resize(h)
		col.fill(-1)
		_occupancy.append(col)

## 检查矩形区域是否空闲
func _is_area_free(x: int, y: int, size: Vector2i) -> bool:
	for dx in range(size.x):
		var col: Array = _occupancy[x + dx]
		for dy in range(size.y):
			if col[y + dy] != -1:
				return false
	return true

## 将矩形区域标记为属于 room_idx
func _occupy_area(pos: Vector2i, size: Vector2i, room_idx: int) -> void:
	for dx in range(size.x):
		var col: Array = _occupancy[pos.x + dx]
		for dy in range(size.y):
			col[pos.y + dy] = room_idx
