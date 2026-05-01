extends Node2D
## 进出地牢不同层
class_name LayerDoor

@export var up_down: bool = true ## up为true

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var area_2d: Area2D = $Area2D

var player_in_range: bool = false

func _ready() -> void:
	self.visibility_changed.connect(_on_visibility_changed)
	area_2d.body_entered.connect(_on_body_entered)
	area_2d.body_exited.connect(_on_body_exited)
	_updata_sprite()

@onready var timer: Timer = $Timer
func _unhandled_input(event: InputEvent) -> void:
	if not player_in_range and not timer.is_stopped():
		return
	if event.is_action_pressed(&"dash"):
		if Global.Layer_Manager:
			timer.start()
			player_in_range = false # 防止区域重复触发
			Global.Layer_Manager.switch_layer(up_down)
			
func _on_body_entered(body: Node2D):
	player_in_range = true
	if body is Player:
		player_in_range = true

func _on_body_exited(body: Node2D):
	player_in_range = false
	if body is Player:
		player_in_range = false

func _on_visibility_changed():
	area_2d.call_deferred(&"set_monitoring", visible)

		
func _updata_sprite():
	sprite_2d.frame = 0 if up_down else 1
