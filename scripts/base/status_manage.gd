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
static func get_base_status() -> Dictionary[String,StatusManage.Status]:
	return {
		##移动状态
		move=MoveBase.new(),
		##主动状态
		proactive=ProactiveBase.new(),
		##被动状态
		passive=PassiveBase.new(),
	}

##获取状态机
static func get_status(key :Dictionary[String,int]={}) -> Dictionary[String,StatusManage.Status]:
	if key.is_empty():
		key=StatusManage.get_base_key()
	var hash_key=hash(key)
	if StatusManage._warehouse.get(hash_key) == null:
		##组装并入库
		StatusManage._warehouse[hash_key]=StatusManage._assemble_status(key)
	return StatusManage._warehouse[hash_key]


##组装状态机
static func _assemble_status(key :Dictionary[String,int]) -> Dictionary[String,StatusManage.Status]:
	var base_status = StatusManage.get_base_status();
	base_status.move.enter(base_status,key.move)
	base_status.proactive.enter(base_status,key.proactive)
	base_status.passive.enter(base_status,key.passive)
	return base_status


##状态基类
@abstract
class Status:
	##获取状态标识
	@abstract
	func get_status_key()

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

	func get_status_key():
		return StatusManage.MOVE_LIST.MOVE_BASE

	func enter(status,enter :StatusManage.MOVE_LIST):
		print("切换移动状态: ", enter)
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
	

	##移动方法
	func move(player :CharacterBody2D,move_input :Vector2):
		self.enter(player.status,StatusManage.MOVE_LIST.WALK)
		pass


##主动状态基类
class ProactiveBase extends Status:

	func get_status_key():
		return StatusManage.PASSIVE_LIST.PASSIVE_BASE

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

	func get_status_key():
		return StatusManage.PASSIVE_LIST.PASSIVE_BASE

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

	func get_status_key():
		return StatusManage.MOVE_LIST.IDLE

	pass

##移动状态
class Walk extends MoveBase:

	func get_status_key():
		return StatusManage.MOVE_LIST.WALK

	func move(player :CharacterBody2D,move_input :Vector2):
		if move_input == Vector2.ZERO:
			self.enter(player.status,StatusManage.MOVE_LIST.IDLE)
		else :
			player.transform = player.transform.translated(move_input)
			print("移动: ", move_input)
	pass

##快速移动状态
class Run extends MoveBase:

	func get_status_key():
		return StatusManage.MOVE_LIST.RUN

	func move(player :CharacterBody2D,move_input :Vector2):
		if move_input == Vector2.ZERO:
			self.enter(player.status,StatusManage.MOVE_LIST.IDLE)
		else :
			player.transform = player.transform.translated(move_input*1.2)
			print("快速移动: ", move_input*1.2)
	pass

##追击状态
class Chase extends MoveBase:

	func get_status_key():
		return StatusManage.MOVE_LIST.CHASE

	pass

##冲刺状态
class Dash extends MoveBase:

	func get_status_key():
		return StatusManage.MOVE_LIST.DASH
	
	func move(player :CharacterBody2D,move_input :Vector2):
		if move_input == Vector2.ZERO:
			self.enter(player.status,StatusManage.MOVE_LIST.IDLE)
		else :
			player.transform = player.transform.translated(move_input*1.5)
			print("冲刺: ", move_input*1.5)

	pass


##攻击状态
class Attack extends ProactiveBase:

	func get_status_key():
		return StatusManage.PROACTIVE_LIST.ATTACK

	pass

##闪避状态
class Dodge extends ProactiveBase:

	func get_status_key():
		return StatusManage.PROACTIVE_LIST.DODGE

	pass


##僵直状态
class Stun extends PassiveBase:

	func get_status_key():
		return StatusManage.PASSIVE_LIST.STUN

	pass
