## 敌怪基类 — 组件化的 CharacterBody2D
## 子节点必须包含：
##   EnemyStateMachine  EnemyMovement  EnemyDetection
##   HurtboxComponent (内含 HealthComponent)  HitboxComponent
##   以及至少一个 EnemyAttack 子类（Melee/Ranged/Contact）
##
## 工作流程：
##   1. 场景实例化后由 EnemyFactory 设置 config
##   2. _ready() 中查找组件、应用配置、组装状态机、连接死亡信号
##   3. config 的 setter 在 _ready() 前触发时仅存储，等进入场景树后再应用
extends CharacterBody2D
class_name BaseEnemy

## 敌怪配置（Resource），设置即应用
@export var config: EnemyConfig:
	set(v):
		config = v
		if v and is_inside_tree():
			_apply_config()

## 子组件引用
@onready var state_machine: EnemyStateMachine = $EnemyStateMachine
@onready var movement: EnemyMovement = $EnemyMovement
@onready var detection: EnemyDetection = $EnemyDetection
@onready var health_component: HealthComponent = $HurtboxComponent/HealthComponent
@onready var hurtbox: HurtboxComponent = $HurtboxComponent
@onready var hitbox: HitboxComponent = $HitboxComponent

var _attack: EnemyAttack


func _ready() -> void:
	add_to_group(&"enemy")

	# 查找攻击组件（子节点中第一个 EnemyAttack 子类实例）
	for child in get_children():
		if child is EnemyAttack:
			_attack = child

	if config:
		_apply_config()

	# 组装状态机
	if state_machine and detection and movement:
		state_machine.setup(detection, movement, _attack, config if config else null)

	# 监听死亡
	if health_component:
		health_component.died.connect(_on_died)


## 将 EnemyConfig 的各个字段分发到对应子组件
func _apply_config() -> void:
	if movement:
		movement.move_speed = config.move_speed
		movement.acceleration = config.acceleration
		movement.use_pathfinding = config.has_pathfinding
		movement.terrain_restricted = config.terrain_restricted

	if detection:
		detection.detection_radius = config.detection_radius

	if health_component:
		health_component.max_health = config.max_health
		health_component.current_health = config.max_health

	# 根据攻击类型配置对应攻击组件
	match config.attack_type:
		EnemyConfig.AttackType.MELEE:
			if hitbox:
				hitbox.damage = config.attack_damage
		EnemyConfig.AttackType.CONTACT:
			var contact := _find_attack(EnemyAttackContact)
			if contact:
				contact.damage = config.attack_damage
		EnemyConfig.AttackType.RANGED:
			var ranged := _find_attack(EnemyAttackRanged)
			if ranged:
				ranged.attack_range = config.far_attack_range
				ranged.bullet_scene = config.bullet_scene
				ranged.bullet_data = config.bullet_data
				ranged.damage = config.attack_damage

	if _attack:
		# RANGED 的 attack_range 已在上面分支设为 far_attack_range，跳过以防覆盖
		if config.attack_type != EnemyConfig.AttackType.RANGED:
			_attack.attack_range = config.attack_range
		_attack.attack_interval = config.attack_interval
		_attack.damage = config.attack_damage


## 在子节点中查找指定类型的攻击组件
func _find_attack(type: Variant) -> EnemyAttack:
	for child in get_children():
		if is_instance_of(child, type):
			return child
	return null


func _on_died() -> void:
	queue_free()
