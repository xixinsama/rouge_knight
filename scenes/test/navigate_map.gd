extends TileMapLayer

@onready var astar_find_path: AstarFindPath = $AstarFindPath

func _ready():
	astar_find_path.initialize()
