extends Node
class_name StatusComponent

## 当前活跃的状态效果
var _active_effects: Array[StatusEffect] = []
## 关联的血量组件（用于燃烧跳伤）
@export var health_component: HealthComponent

## 减速倍率（由 SLOW 效果聚合，默认 1.0）
var speed_multiplier: float = 1.0:
	get:
		for eff in _active_effects:
			if eff.type == StatusEffect.Type.SLOW:
				return minf(speed_multiplier, eff.power)
		return 1.0

## 是否可以移动（FREEZE 效果锁定）
var can_move: bool:
	get:
		for eff in _active_effects:
			if eff.type == StatusEffect.Type.FREEZE:
				return false
		return true

var _burn_timers: Dictionary = {}  # effect -> time_since_last_tick


func apply_effect(effect: StatusEffect) -> void:
	var dup := effect.duplicate() as StatusEffect
	_active_effects.append(dup)
	if dup.type == StatusEffect.Type.BURN:
		_burn_timers[dup] = 0.0
	_remove_after_delay(dup)


func _process(delta: float) -> void:
	_process_burn(delta)
	_process_timed_effects(delta)


func _process_burn(delta: float) -> void:
	for eff in _active_effects:
		if eff.type != StatusEffect.Type.BURN:
			continue
		if not health_component:
			continue
		_burn_timers[eff] += delta
		if _burn_timers[eff] >= eff.tick_interval:
			_burn_timers[eff] -= eff.tick_interval
			health_component.take_damage(int(eff.power))


func _process_timed_effects(delta: float) -> void:
	for eff in _active_effects:
		eff.duration -= delta


func _remove_after_delay(effect: StatusEffect) -> void:
	await get_tree().create_timer(effect.duration).timeout
	_active_effects.erase(effect)
	if effect.type == StatusEffect.Type.BURN:
		_burn_timers.erase(effect)
