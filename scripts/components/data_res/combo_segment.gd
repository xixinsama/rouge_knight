extends Resource
class_name ComboSegment

@export var windup_time: float
@export var active_time: float
@export var recovery_time: float
@export var damage_multiplier: float = 1.0
@export var impact_level: int = 2
@export var animation_name: String
## 此段结束后允许输入下一段的窗口时间（从本段恢复开始计时）
@export var combo_input_window: float = 0.3
