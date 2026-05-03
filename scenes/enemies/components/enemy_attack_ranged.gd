## 远程攻击 — 通过 Global.Bullet_Factory 生成弹幕射向目标
extends EnemyAttack
class_name EnemyAttackRanged

## 弹幕场景（PackedScene），由 EnemyConfig.bullet_scene 注入
@export var bullet_scene: PackedScene
## 弹幕数据（Resource），由 EnemyConfig.bullet_data 注入
@export var bullet_data: BulletData


## 向目标方向生成一颗子弹，发射后立即结束攻击动作
func _perform_attack(target: Node2D) -> void:
	super(target)
	if bullet_scene and bullet_data and Global.Bullet_Factory:
		var pos := (get_parent() as Node2D).global_position
		var dir := pos.direction_to(target.global_position)
		Global.Bullet_Factory.spawn(bullet_data, bullet_scene, pos, dir, get_parent())
	attack_finished.emit()
