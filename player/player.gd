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
var status :Dictionary:
	set(value):
		move=value.move
		proactive=value.proactive
		passive=value.passive


##移动状态机
var move :StatusManage.MoveBase

##主动状态机
var proactive :StatusManage.ProactiveBase

##被动状态机
var passive :StatusManage.PassiveBase

@export_group("")

func _ready() -> void:
	self.status=StatusManage.get_status()
	pass
