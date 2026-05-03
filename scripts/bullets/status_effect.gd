extends Resource
class_name StatusEffect

enum Type { BURN, SLOW, FREEZE }

## 效果类型
@export var type: Type = Type.BURN
## 持续时间
@export var duration: float = 3.0
## 跳伤间隔（仅 BURN）
@export var tick_interval: float = 1.0
## 效果强度（BURN=每跳伤害, SLOW=速度倍率 0~1, FREEZE 忽略）
@export var power: float = 5.0
