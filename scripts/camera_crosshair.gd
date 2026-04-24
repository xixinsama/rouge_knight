extends AnimatedSprite2D

func _ready() -> void:
	InputTest.input_type_changed.connect(show_crosshair)
	show_crosshair()
	
func show_crosshair() -> void:
	if InputTest.last_input_type == InputTest.InputType.GAMEPAD:
		show()
		set_process(true)
	else: 
		hide()
		set_process(false)

## 让其一直旋转
var rotation_speed: float = 2.0
func _process(delta: float) -> void:
	rotation += delta * rotation_speed
