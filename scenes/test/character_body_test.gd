extends CharacterBody2D
## 俯视角2D角色控制器

const MoveUp: StringName = &"move_up"
const MoveDown: StringName = &"move_down"
const MoveLeft: StringName = &"move_left"
const MoveRight: StringName = &"move_right"
const Dash: StringName = &"dash"
const Run: StringName = &"run"

@export var walk_speed: float = 200.0
@export var run_speed: float = 300.0
@export var dash_speed: float = 400.0

@onready var hurtbox_component: HurtboxComponent = $HurtboxComponent

func _ready() -> void:
	hurtbox_component.health_component.damaged.connect(get_damage)

const FLOATING_TEXT = preload("res://scenes/FloatingText.tscn")
func get_damage(damage: int, _current_health: int):
	if damage > 0:
		## 效果
		# 镜头抖动
		var camera: CameraController = CameraController.current
		camera.hit_shake()
		# 手柄振动
		Input.start_joy_vibration(0, 0.5, 0.3, 0.3)

	var FT: FloatingText = FLOATING_TEXT.instantiate()
	FT.global_position = self.global_position
	if Global.Floating_Texts:
		Global.Floating_Texts.add_child(FT)
	else:
		add_child(FT)
	if FT:
		FT.display_damage_text(str(damage))

func _physics_process(_delta: float) -> void:
	var input_vector: Vector2 = Vector2.ZERO
	input_vector.y -= Input.get_action_strength(MoveUp)
	input_vector.y += Input.get_action_strength(MoveDown)
	input_vector.x -= Input.get_action_strength(MoveLeft)
	input_vector.x += Input.get_action_strength(MoveRight)
	velocity = input_vector.normalized() * walk_speed
	move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(Dash):
		velocity = velocity.normalized() * dash_speed
	elif event.is_action_pressed(Run):
		velocity = velocity.normalized() * run_speed
		
