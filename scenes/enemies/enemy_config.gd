## 敌怪配置 Resource — 定义敌怪的所有行为参数
## 在编辑器中创建 .tres 文件，拖入 EnemyFactory 或 BaseEnemy 即可使用
extends Resource
class_name EnemyConfig

## 行为模式：追击 / 追击并攻击 / 站桩射击 / 逃离
enum Behavior { CHASE, CHASE_AND_ATTACK, STAND_AND_SHOOT, FLEE }
## 攻击类型：碰撞伤害 / 近战判定 / 远程弹幕
enum AttackType { CONTACT, MELEE, RANGED }

## 敌怪标识（用于调试和配置表对应）
@export var enemy_id: String = ""
## 最大生命值（小怪默认 1，一刀斩杀）
@export var max_health: int = 1
## 移动速度（像素/秒）
@export var move_speed: float = 80.0
## 加速度（像素/秒²）
@export var acceleration: float = 400.0
## 检测玩家的半径（像素）
@export var detection_radius: float = 300.0
## 攻击范围 — 近战/接触（像素）
@export var attack_range: float = 50.0
## 远程攻击范围（像素）
@export var far_attack_range: float = 400.0
## 攻击冷却间隔（秒）
@export var attack_interval: float = 1.5
## 攻击类型
@export var attack_type: AttackType = AttackType.CONTACT
## 攻击伤害
@export var attack_damage: int = 10
## 行为模式
@export var behavior: Behavior = Behavior.CHASE
## 是否使用 A* 寻路（false = 直线追向玩家）
@export var has_pathfinding: bool = true
## 是否有地形限制（false = 可穿墙）
@export var terrain_restricted: bool = true
## 远程弹幕场景（仅 RANGED 类型使用）
@export var bullet_scene: PackedScene
## 远程弹幕数据（仅 RANGED 类型使用）
@export var bullet_data: BulletData
