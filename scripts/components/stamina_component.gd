extends Node
class_name StaminaComponent

signal stamina_changed(current, max)
signal stamina_broken()

@export var max_stamina: int = 100
@export var current_stamina: int = max_stamina:
	set(v):
		current_stamina = clamp(v, 0, max_stamina)
		stamina_changed.emit(current_stamina, max_stamina)
		if current_stamina <= 0:
			stamina_broken.emit()

@export var regen_rate: float = 10.0 ## 每秒恢复体力值
@export var dash_cost: int = 20 ## 冲刺消耗
@export var sprint_cost_per_sec: float = 15.0 ## 奔跑每秒消耗（player）
@export var dash_distance_full: float = 150.0 ## 满体力冲刺距离
@export var dash_distance_penalty: float = 1.0 ## 体力不足时冲刺距离衰减系数

var can_act: bool = true   # 体力为零时可能无法格挡/弹反/冲刺

func _physics_process(delta):
	if current_stamina < max_stamina:
		current_stamina += regen_rate * delta
