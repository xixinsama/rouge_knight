extends CharacterBody2D
class_name Player

static var current: Player

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
@onready var attack_component: AttackComponent = $AttackComponent
@onready var timer: Timer = $Timer

func _ready() -> void:
	timer.timeout.connect(_attack)
	hurtbox_component.health_component.damaged.connect(get_damage)
	
	# 初始化完成后赋予引用
	current = self

func get_damage(damage: int, _current_health: int):
	if damage > 0:
		## 效果
		# 镜头抖动
		var camera: CameraController = CameraController.current
		camera.hit_shake()
		# 手柄振动
		Input.start_joy_vibration(0, 0.5, 0.3, 0.3)

	if Global.Floating_Texts:
		var ft: FloatingText = Global.Floating_Texts.spawn(self.global_position)
		ft.display_damage_text(str(damage))

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
		

func _attack():
	timer.start()
	attack_component.request_attack()


	
