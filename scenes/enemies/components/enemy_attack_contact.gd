## 接触伤害攻击 — 不需要主动攻击动作，与玩家碰撞即造成伤害
## 通过 HitboxComponent.body_entered/exited 跟踪重叠的玩家，
## 首次接触立刻伤害，持续重叠时按 attack_interval 周期造成后续伤害
extends EnemyAttack
class_name EnemyAttackContact

## 跟踪当前重叠的玩家实体：{body: cooldown_remaining}
var _contact_bodies: Dictionary = {}
var _hitbox: HitboxComponent


func _ready() -> void:
	set_physics_process(false)

	var parent := get_parent()
	if not parent:
		return

	_hitbox = parent.get_node_or_null("HitboxComponent") as HitboxComponent
	if not _hitbox:
		return

	# 确保 hitbox 能检测到 player_entity 层的 CharacterBody
	_hitbox.collision_mask |= 2
	_hitbox.body_entered.connect(_on_body_entered)
	_hitbox.body_exited.connect(_on_body_exited)


## 玩家首次进入碰撞区域：立即造成一次伤害，并开始跟踪后续周期伤害
func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group(&"player"):
		return
	# 首次伤害
	_deal_damage_to_body(body)
	# 加入跟踪，冷却设为 attack_interval，后续由 _physics_process 周期触发
	_contact_bodies[body] = attack_interval
	set_physics_process(true)


## 玩家离开碰撞区域：停止跟踪
func _on_body_exited(body: Node2D) -> void:
	_contact_bodies.erase(body)
	if _contact_bodies.is_empty():
		set_physics_process(false)


## 每物理帧检查重叠的玩家，冷却到零时造成一次伤害
func _physics_process(delta: float) -> void:
	for body in _contact_bodies.keys():
		if not is_instance_valid(body) or not _hitbox.overlaps_body(body):
			_contact_bodies.erase(body)
			continue

		_contact_bodies[body] -= delta
		if _contact_bodies[body] <= 0.0:
			_deal_damage_to_body(body)
			_contact_bodies[body] = attack_interval

	if _contact_bodies.is_empty():
		set_physics_process(false)


## 对玩家实体造成伤害：遍历子节点找到 HurtboxComponent → HealthComponent
func _deal_damage_to_body(body: Node2D) -> void:
	for child in body.get_children():
		if child is HurtboxComponent and child.health_component:
			child.health_component.take_damage(damage)
			return
