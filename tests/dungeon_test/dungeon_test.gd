## 地牢生成测试脚本
## 用法：将此脚本挂载到场景根节点，按 Space 生成，按 1/2/3 切换层
extends Node2D

@onready var camera_2d: Camera2D = $Camera2D
@onready var layer_manager: LayerManager = $LayerManager

@onready var dungeon_generator: DungeonGenerator = $TileMapLayer/DungeonGenerator

## UI
@onready var _info_label: Label = $UI/InfoLabel
@onready var _help_label: RichTextLabel = $UI/HelpLabel

@export var master_seed: int = 114514

var _tilemaps: Array[TileMapLayer] = []
var _current_layer: int = 0
var _current_vis: int = 0

var _gen_time_ms: float = 0.0



func _ready() -> void:
	_tilemaps = layer_manager.all_layers
	SeedManager.set_master_seed(master_seed)
	_generate()

func _generate() -> void:
	var t0 := Time.get_ticks_usec()

	# 生成地牢dungeon_generator
	
	_gen_time_ms = (Time.get_ticks_usec() - t0) / 1000.0
	# _update_info()


#func _update_info() -> void:
	#var level: DungeonDataTypes.DungeonLevel = _data.levels[_current_layer]
	#var total_floor := 0
	#var total_wall := 0
	#for x in range(level.width):
		#for y in range(level.height):
			#var ct = level.grid[x][y]
			#if ct == DungeonGrid.CellType.CELL_WALL:
				#total_wall += 1
			#elif DungeonGrid.is_walkable(ct):
				#total_floor += 1
#
	#var region_count := 0
	#var seen_regions: Dictionary = {}
	#for x in range(level.width):
		#for y in range(level.height):
			#var rid = level.region_grid[x][y]
			#if rid >= 0 and not seen_regions.has(rid):
				#seen_regions[rid] = true
				#region_count += 1
#
	#var text := "Dungeon Test\n"
	#text += "Seed: %d | Gen time: %.1f ms\n" % [_last_seed, _gen_time_ms]
	#text += "Layer: %d/%d | Size: %d×%d\n" % [_current_layer + 1, 3, level.width, level.height]
	#text += "Rooms: %d | Connectors used: %d\n" % [level.rooms.size(), level.used_connectors.size()]
	#text += "Floor cells: %d | Wall cells: %d\n" % [total_floor, total_wall]
	#text += "Regions: %d\n" % region_count
	#text += "Stairs up: %d | Stairs down: %d\n" % [level.stairs_up.size(), level.stairs_down.size()]
	#text += "Key-door pairs: %d\n" % _data.key_door_pairs.size()
#
	##var valid := dungeon_manager._validate_reachability()
	##if valid:
		##text += "Reachability: PASS"
	##else:
		##text += "Reachability: FAIL"
#
	#_info_label.text = text
#
##region 输入
#func _unhandled_input(event: InputEvent) -> void:
	#if event is InputEventKey and event.pressed:
		#match event.keycode:
			##KEY_SPACE:
				##_generate(0)
			##KEY_R:
				##_generate(_last_seed)
			#KEY_1:
				#_switch_layer(0)
			#KEY_2:
				#_switch_layer(1)
			#KEY_3:
				#_switch_layer(2)
			#KEY_V:
				#_cycle_vis()
			#KEY_T:
				#_run_auto_test()
#
	#if event is InputEventMouseButton:
		#if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			#camera_2d.zoom = clamp(camera_2d.zoom + Vector2.ONE * 0.2, Vector2.ONE, 8 * Vector2.ONE) 
		#elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			#camera_2d.zoom = clamp(camera_2d.zoom - Vector2.ONE * 0.2, Vector2.ONE, 8 * Vector2.ONE) 
#
#
#func _process(_delta: float) -> void:
	## 相机平移
	#var speed := 400.0 / camera_2d.zoom.x
	#if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		#camera_2d.position.y -= speed * _delta
	#if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		#camera_2d.position.y += speed * _delta
	#if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		#camera_2d.position.x -= speed * _delta
	#if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		#camera_2d.position.x += speed * _delta
#
#
#func _switch_layer(idx: int) -> void:
	#_current_layer = idx
	#for i in range(3):
		#_tilemaps[i].visible = (i == idx)
	#_update_info()
#
#
#func _cycle_vis() -> void:
	#_current_vis = (_current_vis + 1) % 6
	#var mode_names := ["OFF", "REGIONS", "CONNECTORS", "KEYS_DOORS", "STAIRS", "GRID"]
	#print("Visualization: ", mode_names[_current_vis])
##endregion
#
### 自动化测试：生成50个地牢，验证连通性
#func _run_auto_test() -> void:
	#print("=== Running 50-generation automated test ===")
	#var t0 := Time.get_ticks_usec()
	#var pass_count := 0
	#var fail_count := 0
	#var total_time := 0.0
	#var seeds_failed: Array = []
#
	#for i in range(50):
		#var test_seed := randi()
		#seed(test_seed)
		#var test_gen := DungeonManager.new()
		#test_gen.auto_generate = false
		#var gt0 := Time.get_ticks_usec()
		#var test_data := test_gen.generate_dungeon(test_seed)
		#var gt := (Time.get_ticks_usec() - gt0) / 1000.0
		#total_time += gt
#
		## 保存数据以便验证
		#test_gen._data = test_data
		#if test_gen._validate_reachability():
			#pass_count += 1
		#else:
			#fail_count += 1
			#seeds_failed.append(test_seed)
		#test_gen.queue_free()
#
	#var elapsed := (Time.get_ticks_usec() - t0) / 1000.0
	#var result := "=== Test Complete ===\n"
	#result += "Total: 50 | Pass: %d | Fail: %d\n" % [pass_count, fail_count]
	#result += "Avg gen time: %.1f ms | Total time: %.1f ms\n" % [total_time / 50.0, elapsed]
	#if not seeds_failed.is_empty():
		#result += "Failed seeds: %s\n" % str(seeds_failed)
	#print(result)
	## 更新help显示
	#_help_label.text += "\n\n[color=yellow]%s[/color]" % result.replace("\n", "\n  ")
