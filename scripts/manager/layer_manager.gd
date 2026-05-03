extends Node
class_name LayerManager
## 管理tliemaplayer
## 总共3层

## 切换层时，所有实体冻结
## 当前层放大，透明渐变，取消碰撞
## 目标层从小到大，透明渐变，碰撞生效

@export var all_layers: Array[TileMapLayer]
@export var current_layer_index: int = 0:
	set(v):
		var new_layer_index: int = wrapi(v, 0, all_layers.size())
		switch_layer_anime(current_layer_index, new_layer_index)
		current_layer_index = new_layer_index
		## 更新
		current_layer = all_layers[current_layer_index]
		current_path_finder = all_astar[current_layer_index]

var all_astar: Array[AstarFindPath]
var current_path_finder: AstarFindPath:
	# 同步到 Global
	set(v):
		current_path_finder = v
		Global.Path_Finder = current_path_finder
		
var current_layer: TileMapLayer

func _ready() -> void:
	for layer in all_layers:
		all_astar.append(layer.get_node("AstarFindPath"))
		layer.hide()
		set_layer(layer, false)
	
	current_layer = all_layers[current_layer_index]
	current_path_finder = all_astar[current_layer_index]
	set_layer(current_layer, true)
	current_layer.show()
	

func set_layer(layer: TileMapLayer, value: bool):
	layer.call_deferred(&"set_occlusion_enabled", value)
	layer.call_deferred(&"set_collision_enabled", value)

func switch_layer(up: bool):
	if up: current_layer_index -= 1
	else: current_layer_index += 1

var _tween: Tween
## 强制切换，中途不可暂停
func switch_layer_anime(from_index: int, to_index: int) -> void:
	var from := all_layers[from_index]
	var to := all_layers[to_index]
	
	var _is_up := false \
		if (from_index - to_index) == -1 or (from_index - to_index) == all_layers.size() \
		else true
	# (0, 3)
	# 0 -> 1 down 3 -> 0(4) down
	# 1 -> 0 up 0 -> 3(-1) up 
	
	if from == to:
		return
	if _tween and _tween.is_valid():
		_tween.kill()
	
	# 重置层的视觉和碰撞状态
	from.scale = Vector2(2.0, 2.0)
	from.modulate.a = 1.0
	set_layer(from, false)
	from.show()
	
	to.modulate.a = 0.0
	set_layer(to, false)
	to.show()
	
	var tw = create_tween().set_parallel(true)
	_tween = tw
	
	Input.start_joy_vibration(0, 0.3, 0.8, 0.5)
	
	if not _is_up:
		# 重置目标层的初始动画状态
		to.scale = Vector2.ZERO
		
		tw.tween_property(from, "scale", Vector2(4.0, 4.0), 0.5).set_ease(Tween.EASE_IN)
		tw.tween_property(from, "modulate:a", 0.0, 0.5)
		tw.tween_property(to, "scale", Vector2(2.0, 2.0), 0.5).set_ease(Tween.EASE_IN)
		tw.tween_property(to, "modulate:a", 1.0, 0.5)
		
		await tw.finished
	else:
		## 向上, to 层由大变小
		to.scale = Vector2(4.0, 4.0)
		
		tw.tween_property(from, "scale", Vector2.ZERO, 0.5).set_ease(Tween.EASE_OUT)
		tw.tween_property(from, "modulate:a", 0.0, 0.5)
		tw.tween_property(to, "scale", Vector2(2.0, 2.0), 0.5).set_ease(Tween.EASE_OUT)
		tw.tween_property(to, "modulate:a", 1.0, 0.5)
		
		await tw.finished
	# 如果动画被打断（新切换发生），则不再处理旧动画的结束状态
	if tw != _tween or not is_instance_valid(tw):
		return
	
	# 动画正常结束，启用目标层，隐藏来源层
	set_layer(to, true)
	from.hide()
	# 恢复来源层变换（保持干净状态）
	from.scale = Vector2.ONE
	from.modulate.a = 1.0
	
	current_layer = to
