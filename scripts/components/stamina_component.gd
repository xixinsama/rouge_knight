extends Node
class_name StaminaComponent 

var max_stamina: int = 100
var current_stamina: int = max_stamina
var stamina_regen_rate: int = 5 ## 每秒自动恢复的体力值（未受击且未行动时）
