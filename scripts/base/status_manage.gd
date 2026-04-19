##状态机基类	[br]
##单例调用(挂载到全局自动加载)	[br]
##建造者模式	[br]
extends Node
class_name StatusManage

@export_group("状态枚举")
##移动状态枚举
enum MOVE_LIST{
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

##主动状态枚举
enum PROACTIVE_LIST{
	##默认基类
	PROACTIVE_BASE,
	##攻击状态
	ATTACK,
	##闪避状态
	DODGE,
	MAX,
}

##被动状态枚举
enum PASSIVE_LIST{
	##默认基类
	PASSIVE_BASE,
	##僵直状态
	STUN,
	MAX
}
@export_group("")


##产品仓库(状态列表)
static var _warehouse :Dictionary[int,Dictionary] = {}

func _ready() -> void:
	pass


##获取默认标识
static func get_base_key() -> Dictionary[String,int]:
	return {
		##移动状态
		move=MOVE_LIST.MOVE_BASE,
		##主动状态
		proactive=PROACTIVE_LIST.PROACTIVE_BASE,
		##被动状态
		passive=PASSIVE_LIST.PASSIVE_BASE,
	}

##获取默认状态机
static func get_base_status() -> Dictionary[String,Variant]:
	return {
		##移动状态
		move=MoveBase.new(),
		##主动状态
		proactive=ProactiveBase.new(),
		##被动状态
		passive=PassiveBase.new(),
	}

##获取状态机
static func get_status(key :Dictionary[String,int]={}) -> Dictionary[String,Variant]:
	if key.is_empty():
		key=StatusManage.get_base_key()
	var hash_key=hash(key)
	if StatusManage._warehouse.get(hash_key) == null:
		##组装并入库
		StatusManage._warehouse[hash_key]=StatusManage._assemble_status(key)
	return StatusManage._warehouse[hash_key]


##组装状态机
static func _assemble_status(key :Dictionary[String,int]) -> Dictionary[String,Variant]:
	var base_status = StatusManage.get_base_status();
	base_status.move.enter(base_status,key.move)
	base_status.proactive.enter(base_status,key.proactive)
	base_status.passive.enter(base_status,key.passive)
	return base_status


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
	func enter(status,enter :StatusManage.MOVE_LIST):
		if enter == StatusManage.MOVE_LIST.MOVE_BASE :
			status.move=MoveBase.new()
		elif enter == StatusManage.MOVE_LIST.IDLE :
			status.move=Idle.new()
		elif enter == StatusManage.MOVE_LIST.WALK :
			status.move=Walk.new()
		elif enter == StatusManage.MOVE_LIST.RUN :
			status.move=Run.new()
		elif enter == StatusManage.MOVE_LIST.CHASE :
			status.move=Chase.new()
		elif enter == StatusManage.MOVE_LIST.DASH :
			status.move=Dash.new()
		else :
			status.move=MoveBase.new()
		pass


##主动状态基类
class ProactiveBase extends Status:
	##状态切换
	func enter(status,enter :StatusManage.PROACTIVE_LIST):
		if enter==StatusManage.PROACTIVE_LIST.PROACTIVE_BASE:
			status.proactive=ProactiveBase.new()
		elif enter==StatusManage.PROACTIVE_LIST.ATTACK:
			status.proactive=Attack.new()
		elif enter==StatusManage.PROACTIVE_LIST.DODGE:
			status.proactive=Dodge.new()
		else :
			status.proactive=ProactiveBase.new()


##被动状态基类
class PassiveBase extends Status:
	func enter(status,enter :StatusManage.PASSIVE_LIST):
		if enter==StatusManage.PASSIVE_LIST.PASSIVE_BASE:
			status.passive=PassiveBase.new()
		elif enter==StatusManage.PASSIVE_LIST.STUN:
			status.passive=Stun.new()
		else :
			status.passive=PassiveBase.new()
		pass




##待机状态
class Idle extends MoveBase:
	pass

##移动状态
class Walk extends MoveBase:
	pass

##快速移动状态
class Run extends MoveBase:
	pass

##追击状态
class Chase extends MoveBase:
	pass

##冲刺状态
class Dash extends MoveBase:
	pass


##攻击状态
class Attack extends ProactiveBase:
	pass

##闪避状态
class Dodge extends ProactiveBase:
	pass


##僵直状态
class Stun extends PassiveBase:
	pass
