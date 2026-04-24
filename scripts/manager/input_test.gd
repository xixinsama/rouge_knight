## InputDetector.gd
## 检测最近一次输入的是键盘还是手柄
## 一般用于更改UI显示
## 不消耗输入事件
extends Node

enum InputType { KEYBOARD, GAMEPAD }

var last_input_type := InputType.KEYBOARD
var _gamepad_deadzone := 0.1 # 摇杆死区
var connected_gamepads := [] # 检测手柄连接变化

signal input_type_changed

func _ready():
	Input.joy_connection_changed.connect(_on_joy_connection_changed)

func _on_joy_connection_changed(device_id: int, connected: bool):
	if connected:
		connected_gamepads.append(device_id)
	else:
		connected_gamepads.erase(device_id)

func _input(event: InputEvent) -> void:
	var new_type = null
	if is_keyboard_event(event):
		new_type = InputType.KEYBOARD
	elif is_gamepad_event(event):
		new_type = InputType.GAMEPAD
	else: pass
	
	# 非键盘且非手柄事件，忽略
	if new_type == null:
		return 

	if new_type != last_input_type:
		last_input_type = new_type
		input_type_changed.emit()

func is_keyboard_event(event: InputEvent) -> bool:
	return (event is InputEventKey and event.pressed) or \
		   (event is InputEventMouseButton and event.pressed)

func is_gamepad_event(event: InputEvent) -> bool:
	if event is InputEventJoypadButton:
		return event.pressed
	
	if event is InputEventJoypadMotion:
		return abs(event.axis_value) > _gamepad_deadzone
	
	return false

## 返回当前输入设备的名字
func get_input_type_name() -> String:
	return "键盘" if last_input_type == InputType.KEYBOARD else "手柄"
