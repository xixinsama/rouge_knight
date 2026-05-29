## 地牢网格工具 — 纯静态工具函数 + CellType枚举
## 所有坐标操作均为环面(toroidal)感知
class_name DungeonGrid
extends RefCounted

enum CellType {
	CELL_FLOOR         = 0,   ## 通路（空地）
	CELL_WALL_PRIOR    = 1,   ## 墙（优先破坏）
	CELL_WALL_NORMAL   = 2,   ## 墙
	CELL_WALL_STATIC   = 3,   ## 墙（不可破坏）
	CELL_DOOR_NORMAL   = 4,   ## 门（普通）
	CELL_DOOR_LOCKED   = 5,   ## 门（上锁）
	CELL_DOOR_BARRED   = 6,   ## 门（禁止破坏）
	CELL_VOID_INTERNAL = 7,   ## 虚空（内部/掉落）
	CELL_VOID_EXTERNAL = 8,   ## 虚空（外部/边界）
	CELL_STAIRS_UP     = 9,   ## 楼梯（上行）
	CELL_STAIRS_DOWN   = 10,  ## 楼梯（下行）
	CELL_PLACEHOLDER   = 11,  ## 占位（生成中）
}

## 是否为可行走的地面（包括门、楼梯、虚空内部）
static func is_walkable(cell_type: int) -> bool:
	return cell_type in [
		CellType.CELL_FLOOR,
		CellType.CELL_DOOR_NORMAL,
		CellType.CELL_DOOR_LOCKED,
		CellType.CELL_DOOR_BARRED,
		CellType.CELL_VOID_INTERNAL,
		CellType.CELL_STAIRS_UP,
		CellType.CELL_STAIRS_DOWN,
	]

## 是否为实心障碍物
static func is_solid(cell_type: int) -> bool:
	return cell_type in [CellType.CELL_WALL_NORMAL, CellType.CELL_VOID_EXTERNAL, CellType.CELL_PLACEHOLDER]

## 是否为门类型
static func is_door(cell_type: int) -> bool:
	return cell_type in [CellType.CELL_DOOR_NORMAL, CellType.CELL_DOOR_LOCKED, CellType.CELL_DOOR_BARRED]

## 环面坐标包装
static func map_wrap(v: int, size: int) -> int:
	return posmod(v, size)

## 获取环面4-邻域坐标
static func get_neighbors(x: int, y: int, w: int, h: int) -> Array[Vector2i]:
	return [
		Vector2i(map_wrap(x + 1, w), y),
		Vector2i(map_wrap(x - 1, w), y),
		Vector2i(x, map_wrap(y + 1, h)),
		Vector2i(x, map_wrap(y - 1, h)),
	]

## 获取环面8-邻域坐标（含对角）
static func get_neighbors_8(x: int, y: int, w: int, h: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			out.append(Vector2i(map_wrap(x + dx, w), map_wrap(y + dy, h)))
	return out

## 创建并填充二维数组
static func make_grid_2d(w: int, h: int, fill_value: int) -> Array:
	var grid: Array = []
	for x in range(w):
		var col: Array = []
		col.resize(h)
		col.fill(fill_value)
		grid.append(col)
	return grid

## 复制二维数组
static func copy_grid_2d(src: Array) -> Array:
	var out: Array = []
	for x in range(src.size()):
		out.append(src[x].duplicate())
	return out
