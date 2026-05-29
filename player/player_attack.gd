extends Node2D

@export var rotation_speed: float = 5.0
@export var gamepad_deadzone: float = 0.3

var _target_angle: float = 0.0


func _ready() -> void:
	_target_angle = rotation


func _physics_process(delta: float) -> void:
	var input_dir := Vector2.ZERO

	if InputTest.last_input_type == InputTest.InputType.GAMEPAD:
		input_dir.x = Input.get_joy_axis(0, JOY_AXIS_RIGHT_X)
		input_dir.y = Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
		if input_dir.length() < gamepad_deadzone:
			return
	else:
		var mouse_pos := get_global_mouse_position()
		input_dir = mouse_pos - global_position

	if input_dir.length_squared() > 0.01:
		_target_angle = input_dir.angle()

	rotation = lerp_angle(rotation, _target_angle, rotation_speed * delta)
