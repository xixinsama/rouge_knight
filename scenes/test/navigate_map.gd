extends TileMapLayer

var _astar := AStarGrid2D.new()

func _ready():
	# 初始化A*算法
	_astar.region = get_used_rect()
	_astar.cell_size = Vector2(16, 16)
	_astar.update()

	# 设置障碍物
	for cell in get_used_cells():
		if get_cell_alternative_tile(cell) == 1:
			_astar.set_point_solid(cell)
	
	

	print(_astar.get_id_path(Vector2i(0, -3), Vector2i(4, 10)))
