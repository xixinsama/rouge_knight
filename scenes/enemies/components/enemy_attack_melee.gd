## 近战攻击 — 短暂激活父节点的 HitboxComponent，通过 area_entered 命中玩家 Hurtbox
extends EnemyAttack
class_name EnemyAttackMelee

## 攻击判定窗口（秒），期间 hitbox 保持 active
const MELEE_WINDOW: float = 0.3

var _hitbox: HitboxComponent


func _ready() -> void:
	_hitbox = get_parent().get_node_or_null("HitboxComponent") as HitboxComponent


## 激活 hitbox 持续 MELEE_WINDOW 秒，命中由 HitboxComponent → HurtboxComponent 信号链处理
func _perform_attack(target: Node2D) -> void:
	super(target)
	if _hitbox:
		_hitbox.active = true
		_hitbox.damage = damage
		await get_tree().create_timer(MELEE_WINDOW).timeout
		if is_instance_valid(_hitbox):
			_hitbox.active = false
	attack_finished.emit()
