extends TileMapLayer

@onready var astar_find_path: AstarFindPath = $AstarFindPath
var path
@onready var node_2d: Node2D = $"../Node2D"

func _ready():
	astar_find_path.initialize()
	#path = astar_find_path.find_path(Vector2.ZERO, Vector2(160, 300))
	#print(path)
	##draw_polyline(path, Color.WHITE_SMOKE, 2)
	#node_2d.draw_path(path)
