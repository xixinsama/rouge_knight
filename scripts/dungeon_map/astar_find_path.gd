extends Node
class_name AstarFindPath ## A* 寻路

@export var tile_map_layer: TileMapLayer

var _astar := AStarGrid2D.new()

func _ready() -> void:
	if not tile_map_layer:
		printerr("AstarFindPath未指定TileMapLayer")

## 必须调用才可使用
func initialize() -> void:
	if not tile_map_layer:
		return
	
	# 初始化A*算法
	_astar.region = tile_map_layer.get_used_rect()
	_astar.cell_size = tile_map_layer.tile_set.tile_size
	_astar.update()

	# 设置障碍物
	for cell in tile_map_layer.get_used_cells():
		if tile_map_layer.get_cell_alternative_tile(cell) == 1:
			_astar.set_point_solid(cell)

## 返回最短路径上所有点
func find_path(from_global_pos: Vector2, to_global_pos: Vector2) -> Array[Vector2]:
	var from_id = tile_map_layer.local_to_map(tile_map_layer.to_local(from_global_pos))
	var to_id = tile_map_layer.local_to_map(tile_map_layer.to_local(to_global_pos))
	var id_path := _astar.get_id_path(from_id, to_id)
	var point_path: Array[Vector2] = []
	for i in id_path:
		point_path.append(tile_map_layer.to_global(tile_map_layer.map_to_local(i)))
	
	return point_path

func set_point_passable(point: Vector2i, passable: bool = true):
	_astar.set_point_solid(point, passable)
