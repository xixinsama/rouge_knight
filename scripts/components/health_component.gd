extends Node
class_name HealthComponent ## 血量组件

## 血量变化信号：当前血量，最大血量
signal health_changed(current_health: int, max_health: int)
## 受到伤害信号：伤害值，当前血量
signal damaged(damage: int, current_health: int)
## 死亡信号
signal died()
## 治疗信号：治疗量，当前血量
signal healed(amount: int, current_health: int)

## 最大血量（可在编辑器中调整）
@export var max_health: int = 100
## 当前血量
@export var current_health: int = max_health:
	set(value):
		var old = current_health
		current_health = clamp(value, 0, max_health)
		if current_health != old:
			health_changed.emit(current_health, max_health)

## 是否已死亡
var is_dead: bool:
	get:
		return current_health <= 0

## 是否无敌（受击后短暂无敌）
@export var invincible_time: float = 0.5
var _can_take_damage: bool = true


func _ready() -> void:
	current_health = max_health


## 受到伤害
func take_damage(damage: int) -> void:
	if is_dead or not _can_take_damage:
		return
	
	current_health -= damage
	damaged.emit(damage, current_health)
	
	if is_dead:
		died.emit()
	else:
		_start_invincibility()


## 治疗
func heal(amount: int) -> void:
	if is_dead:
		return
	
	var old = current_health
	current_health += amount
	if current_health > old:
		healed.emit(amount, current_health)


## 重置血量（复活用）
func reset_health() -> void:
	current_health = max_health
	_can_take_damage = true


## 开启无敌
func _start_invincibility() -> void:
	_can_take_damage = false
	await get_tree().create_timer(invincible_time).timeout
	_can_take_damage = true


## 强制结束无敌
func end_invincibility() -> void:
	_can_take_damage = true
