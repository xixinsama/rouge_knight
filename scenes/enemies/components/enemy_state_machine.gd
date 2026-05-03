## 敌怪状态机 — 驱动 IDLE / CHASE / ATTACK / FLEE / STORED 五个状态的切换
## 由 BaseEnemy._ready() 调用 setup() 注入组件引用并连接信号，
## 状态切换逻辑：
##   IDLE  → 玩家进入检测范围 → CHASE
##   CHASE → 进入攻击范围     → ATTACK
##   CHASE → 玩家离开检测范围 → IDLE
##   ATTACK → 攻击完成 / 超出范围 → CHASE
##   *     → 切换地图层      → STORED（冻结，恢复时回到 IDLE）
extends Node
class_name EnemyStateMachine

enum State { IDLE, CHASE, ATTACK, FLEE, STORED }

var current_state: State = State.IDLE

var detection: EnemyDetection
var movement: EnemyMovement
var attack: EnemyAttack

var _player: Node2D
var _config: EnemyConfig


## 注入组件依赖并连接检测/攻击信号
func setup(p_detection: EnemyDetection, p_movement: EnemyMovement, p_attack: EnemyAttack, p_config: EnemyConfig) -> void:
	detection = p_detection
	movement = p_movement
	attack = p_attack
	_config = p_config

	if detection:
		detection.detection_radius = p_config.detection_radius
		detection.player_detected.connect(_on_player_detected)
		detection.player_lost.connect(_on_player_lost)

	if attack:
		attack.attack_finished.connect(_on_attack_finished)


func _process(_delta: float) -> void:
	if current_state == State.STORED:
		return

	match current_state:
		State.IDLE:
			movement.set_mode(EnemyMovement.Mode.WANDER)
		State.CHASE:
			_chase_tick()
		State.ATTACK:
			_attack_tick()
		State.FLEE:
			movement.set_mode(EnemyMovement.Mode.FLEE)


## CHASE 状态每帧逻辑：
## - STAND_AND_SHOOT 行为直接进入 ATTACK
## - CONTACT 伤害类型不进入 ATTACK，靠碰撞造成伤害
## - 其他类型在进入攻击范围后切 ATTACK
func _chase_tick() -> void:
	if not _player:
		return

	if _config and _config.behavior == EnemyConfig.Behavior.STAND_AND_SHOOT:
		current_state = State.ATTACK
		return

	movement.set_mode(EnemyMovement.Mode.CHASE)

	# 接触伤害型敌怪无需进入 ATTACK 状态，碰撞即伤害
	if _config and _config.attack_type == EnemyConfig.AttackType.CONTACT:
		return

	# 检查是否进入攻击范围
	if attack:
		var dist := _body_pos().distance_to(_player.global_position)
		if dist <= attack.attack_range:
			current_state = State.ATTACK


## ATTACK 状态每帧逻辑：
## - 远程单位站立，其余空闲
## - 超出范围回到 CHASE
## - 每帧调用 try_attack，由冷却控制实际攻击频率
func _attack_tick() -> void:
	if not _player or not attack:
		return

	movement.set_mode(EnemyMovement.Mode.IDLE)

	# 超出攻击范围则回到追逐
	var effective_range := attack.attack_range
	if _config and _config.far_attack_range > 0:
		effective_range = _config.far_attack_range

	var dist := _body_pos().distance_to(_player.global_position)
	if dist > effective_range + 30.0:
		current_state = State.CHASE
		return

	attack.try_attack(_player)


func _on_player_detected(player: Node2D) -> void:
	_player = player
	movement.set_target(player)
	current_state = State.CHASE


func _on_player_lost() -> void:
	_player = null
	current_state = State.IDLE


func _on_attack_finished() -> void:
	if current_state == State.ATTACK:
		current_state = State.CHASE


## 地图层切换时冻结敌怪
func store() -> void:
	current_state = State.STORED
	get_parent().set_process(false)
	get_parent().hide()


## 地图层切回时恢复敌怪
func restore() -> void:
	current_state = State.IDLE
	get_parent().set_process(true)
	get_parent().show()


func _body_pos() -> Vector2:
	return (get_parent() as Node2D).global_position
