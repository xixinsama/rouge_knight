extends Resource
class_name BulletData

enum BulletType { NORMAL, BURN, SLOW, FREEZE }

## 弹幕类型
@export var bullet_type: BulletType = BulletType.NORMAL
## 命中伤害
@export var damage: int = 10
## 初始速度
@export var initial_speed: float = 200.0
## 最大速度
@export var max_speed: float = 400.0
## 加速度（每秒）
@export var acceleration: float = 100.0

## 状态效果持续时间（仅 BURN/SLOW/FREEZE 有效）
@export var status_duration: float = 3.0
## 状态效果强度（燃烧=每跳伤害, 减速=速度倍率 0~1, 冰冻忽略）
@export var status_power: float = 5.0
