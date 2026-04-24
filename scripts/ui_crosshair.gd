extends AnimatedSprite2D

func _ready() -> void:
	InputTest.input_type_changed.connect(show_crosshair)
	show_crosshair()
	
func show_crosshair() -> void:
	if InputTest.last_input_type == InputTest.InputType.KEYBOARD:
		show()
		set_process(true)
	else: 
		hide()
		position = GameConst.ScreenSize / 2 ## 居中
		set_process(false)

## 让其一直旋转
## 且跟随鼠标位置
var follow_speed: float = 10.0
var rotation_speed: float = 2.0
func _process(delta: float) -> void:
	position = lerp(position, get_global_mouse_position(), delta*follow_speed)
	self.global_rotation += delta * rotation_speed
