extends Resource
class_name WeaponData

## 基础攻速（次/秒），用于计算冷却
@export var attacks_per_second: float = 2.0

## 攻击阶段时长（秒，基于物理帧率60计算）
@export var windup_time: float = 0.2      # 12帧 / 60
@export var active_time: float = 0.1      # 6帧
@export var recovery_time: float = 0.2    # 12帧

## 伤害倍率（与角色基础攻击力相乘）
@export var damage_multiplier: float = 1.0

## 攻击距离（影响碰撞体大小/位置）
@export var melee_range: float = 50.0

## 攻击的冲击力等级（1~5）
@export var impact_level: int = 2

## 动画名称
@export var animation_name: String = "attack"

## 连击段定义（为空表示无连击）
@export var combo_segments: Array[ComboSegment]
