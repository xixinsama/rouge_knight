extends Node2D

@export var layer_a: TileMapLayer
@export var layer_b: TileMapLayer
@export var cycle_duration: float = 30.0
@export var stage_duration: float = 15.0
@export var interval_max: float = 1.5
@export var interval_min: float = 0.6
@export var default_scale: Vector2 = Vector2(2, 2)
@export var tileset_source_id: int = 0
@export var wall_atlas_coords: Vector2i = Vector2i(9, 2)
@export var wall_alternative: int = 1
@export var road_alternative: int = 0

var active_layer: TileMapLayer
var hidden_layer: TileMapLayer
var is_animating := false
var direction := 1
var stage_elapsed := 0.0
var time_since_switch := 0.0
var current_interval := interval_max
var current_depth := 0


func _ready():
	active_layer = layer_a
	hidden_layer = layer_b
	hidden_layer.hide()
	generate_and_apply_maze(active_layer)
	current_depth = 0
	stage_elapsed = 0.0
	time_since_switch = 0.0
	current_interval = interval_max

const TileMapSize := Vector2(60, 34)
func generate_and_apply_maze(layer: TileMapLayer):
	var maze = MazeGenerator.generate(
		int(TileMapSize.x),
		int(TileMapSize.y), 
		SeedManager.get_rng(get_global_mouse_position()), ## 以鼠标位置为熵
		10,
		0.9
	)
	layer.clear()
	var road_cells: Array[Vector2i] = [] ## 保存道路的网格位置
	for y in range(maze.size()):
		for x in range(maze[y].size()):
			var alt = road_alternative if maze[y][x] == 0 else wall_alternative
			if alt == road_alternative:
				road_cells.append(Vector2i(x, y) - Vector2i(TileMapSize / 2))
			else:
				layer.set_cell(Vector2i(x, y) - Vector2i(TileMapSize / 2), tileset_source_id, wall_atlas_coords, alt)
	layer.set_cells_terrain_connect(road_cells, 0, 0)


func switch_layer(from_layer: TileMapLayer, to_layer: TileMapLayer, is_up: bool, step_dir: int):
	is_animating = true

	from_layer.scale = default_scale
	from_layer.modulate.a = 1.0
	from_layer.show()

	to_layer.modulate.a = 0.0
	to_layer.scale = Vector2.ZERO if not is_up else default_scale * 2.0
	to_layer.show()

	var tw = create_tween().set_parallel(true)

	if not is_up:
		tw.tween_property(from_layer, "scale", default_scale * 2.0, 0.5).set_ease(Tween.EASE_IN)
		tw.tween_property(from_layer, "modulate:a", 0.0, 0.5)
		tw.tween_property(to_layer, "scale", default_scale, 0.5).set_ease(Tween.EASE_IN)
		tw.tween_property(to_layer, "modulate:a", 1.0, 0.5)
	else:
		tw.tween_property(from_layer, "scale", Vector2.ZERO, 0.5).set_ease(Tween.EASE_OUT)
		tw.tween_property(from_layer, "modulate:a", 0.0, 0.5)
		tw.tween_property(to_layer, "scale", default_scale, 0.5).set_ease(Tween.EASE_OUT)
		tw.tween_property(to_layer, "modulate:a", 1.0, 0.5)

	await tw.finished

	# 阻尼振动
	var overshoot = default_scale + Vector2(randf_range(0.1, 0.2), randf_range(0.1, 0.2))
	to_layer.scale = overshoot
	var vibe = create_tween()
	vibe.tween_property(to_layer, "scale", default_scale, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)
	await vibe.finished
	to_layer.scale = default_scale

	from_layer.hide()

	# 交换主次层引用并更新深度
	#var temp = active_layer
	active_layer = to_layer
	hidden_layer = from_layer
	current_depth += step_dir

	is_animating = false


func _process(delta):
	stage_elapsed += delta
	if stage_elapsed >= stage_duration:
		stage_elapsed -= stage_duration
		direction *= -1

	var t = stage_elapsed / stage_duration
	current_interval = lerpf(interval_max, interval_min, t)

	if is_animating:
		return

	time_since_switch += delta
	if time_since_switch >= current_interval:
		time_since_switch -= current_interval
		generate_and_apply_maze(hidden_layer)
		var is_up = (direction == -1)
		switch_layer(active_layer, hidden_layer, is_up, direction)
