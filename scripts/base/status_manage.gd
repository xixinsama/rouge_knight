##状态机基类
##单例调用(挂载到全局自动加载)
##建造者模式
extends Node
class_name StatusManage

@export_group("状态枚举")
##状态枚举
enum MOVE_BASE{
	##默认基类
	MOVE_BASE,
	##待机
	IDLE,
	##移动
	WALK,
	##快速移动
	RUN,
	##追击
	CHASE,
	##冲刺
	DASH,
	MAX,
}


##产品仓库
var warehouse :Dictionary[String,Variant] = {}
##产品原型
var status :Dictionary[String,Status]

func _ready() -> void:
#	移动状态
	self.status.MoveBase=Idle.new()
#	主动状态
	self.status.ProactiveBase=ProactiveDefault.new()
#	被动状态
	self.status.PassiveBase=PassiveDefault.new()
	pass


##定制
func custom():
	
	pass








##状态基类
@abstract
class Status:
	##状态切换
	@abstract
	func enter(status,enter)

##移动状态基类
##idle	待机
##walk  移动
##run   快速移动
##chase 追击
##dash	冲刺
class MoveBase extends Status:
	func enter(status,enter :StatusManage.MOVE_BASE):
		if enter == MOVE_BASE.MOVE_BASE :
			status.move_base=MoveBase.new()
		elif enter == MOVE_BASE.IDLE :
			status.move_base=Idle.new()
		elif enter == MOVE_BASE.WALK :
			status.move_base=Walk.new()
		elif enter == MOVE_BASE.RUN :
			status.move_base=Idle.new()
		pass

##主动状态基类
@abstract
class ProactiveBase extends Status:
	@abstract
	func enter(status,enter :ProactiveBase)

##被动状态基类
@abstract
class PassiveBase extends Status:
	@abstract
	func enter(status,enter :PassiveBase)




##待机状态
class Idle extends MoveBase:
	func enter(status,enter :StatusManage.MOVE_BASE):
		status.MoveBase=enter
		return status.MoveBase

##移动状态
class Walk extends MoveBase:
	func enter(status,enter :StatusManage.MOVE_BASE):
		status.MoveBase=enter
		return status.MoveBase

##快速移动状态
class Run extends MoveBase:
	func enter(status,enter :StatusManage.MOVE_BASE):
		status.MoveBase=enter
		return status.MoveBase

##追击状态
class Chase extends MoveBase:
	func enter(status,enter :StatusManage.MOVE_BASE):
		status.MoveBase=enter
		return status.MoveBase

##冲刺状态
class Dash extends MoveBase:
	func enter(status,enter :StatusManage.MOVE_BASE):
		status.MoveBase=enter
		return status.MoveBase


##主动默认状态
class ProactiveDefault extends ProactiveBase:
	func enter(status,enter :ProactiveBase):
		status.ProactiveBase=enter
		return status.ProactiveBase

##攻击状态
class Attack extends ProactiveBase:
	func enter(status,enter :ProactiveBase):
		status.ProactiveBase=enter
		return status.ProactiveBase

##被动默认状态
class PassiveDefault extends PassiveBase:
	func enter(status,enter :PassiveBase):
		status.PassiveBase=enter
		return status.PassiveBase

##闪避状态
class Dodge extends PassiveBase:
	func enter(status,enter :PassiveBase):
		status.PassiveBase=enter
		return status.PassiveBase


##僵直状态
class Stun extends PassiveBase:
	func enter(status,enter :PassiveBase):
		status.PassiveBase=enter
		return status.PassiveBase
