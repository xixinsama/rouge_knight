extends CharacterBody2D
class_name Player

static var instances: Dictionary

const MoveUp: StringName = &"move_up"
const MoveDown: StringName = &"move_down"
const MoveLeft: StringName = &"move_left"
const MoveRight: StringName = &"move_right"
const Dash: StringName = &"dash"
const Run: StringName = &"run"


@export_group("状态")

##状态	[br]
var status :Dictionary[String,StatusManage.Status]

@export_group("")


@export_group("子节点")

@onready var player_sprite_2d: Sprite2D = $Sprite2D

@export_group("")


@export_group("外部资源")


@export_group("")


@export_group("临时属性")

##移动输入
var move_input :Vector2 = Vector2.ZERO:
	get:
		return move_input
	set(value):
		if value == Vector2.ZERO :
			move_input = Vector2.ZERO
		else :
			if value.x == 0:
				move_input.x = move_input.x/3
			elif value.y == 0:
				move_input.y = move_input.y/3
			move_input += value
			move_input.x = clamp(move_input.x, -10, 10)
			move_input.y = clamp(move_input.y, -10, 10)			
			move_input = move_input.normalized()*5
@export_group("")



func _ready() -> void:
	##加载状态机
	self.status=StatusManage.get_status()
	##加载贴图
	pass




func _physics_process(delta: float) -> void:
	##四向移动
	self.move_input = Input.get_vector(MoveLeft, MoveRight, MoveUp, MoveDown)
	if self.move_input != Vector2.ZERO:
		self.status.move.move(self, self.move_input)
	##快速移动
	if Input.is_action_pressed(Run) && self.status.move.get_status_key() != StatusManage.MOVE_LIST.RUN:
		self.status.move.enter(self.status, StatusManage.MOVE_LIST.RUN)
	##冲刺
	if Input.is_action_pressed(Dash) && self.status.move.get_status_key() != StatusManage.MOVE_LIST.DASH:
		self.status.move.enter(self.status, StatusManage.MOVE_LIST.DASH)
	pass




func _input(event :InputEvent) -> void:
	
	##结束快速移动
	if event.is_action_released(Run) && self.status.move.get_status_key() == StatusManage.MOVE_LIST.RUN:
		self.status.move.enter(self.status, StatusManage.MOVE_LIST.IDLE)
	##结束冲刺
	if event.is_action_released(Dash) && self.status.move.get_status_key() == StatusManage.MOVE_LIST.DASH:
		self.status.move.enter(self.status, StatusManage.MOVE_LIST.IDLE)
	pass




















	
