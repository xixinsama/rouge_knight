@tool
##主武器基类
class_name Weapon
extends Node2D


@export_group("外部属性")

@onready 
var player: Player = $".."

@onready var timer: Timer = $Timer

@onready var animation_player: AnimationPlayer = $AnimationPlayer



@export_group("")



@export_group("基本属性")

##武器名称
@export
var weapon_name :String ="主武器"

##自动攻击开关
@export
var auto_attack_switch :bool = true


##自动攻击间隔		[br]
##自动攻击开关 auto_attack_switch==true时生效		[br]
##受到攻速 attack_speed影响
@onready
var auto_attack_interval :float:
	get:
		return timer.wait_time
	set(value):
		timer.wait_time=1/value

@export_group("")

func _get_configuration_warnings():
	var err_data :Array[String] =[]
	if !has_node("Timer"):
		err_data.append("缺少必需的子节点:Timer!")
	elif ! (get_node("Timer") is Timer):
		err_data.append("子节点'Timer'必须是'Timer'类型!")
	return err_data


func _ready() -> void:
	##连接信号
	timer.timeout.connect(_on_timer_timeout)
	pass


func _process(delta: float) -> void:
	
	pass


func _on_timer_timeout() -> void:
	print("自动攻击"+Time.get_datetime_string_from_system())
	player.status.proactive.attack(animation_player)
	pass # Replace with function body.
