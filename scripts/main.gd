extends Node2D
## 这里不必放什么

func _ready() -> void:
	# 给GLobal 赋值
	Global.Bullet_Factory = $BulletFactory
	Global.Particle_Spawner = $ParticleSpawner
	Global.UI_Layer = $UI
	Global.Screen_Hint = $UI/ScreenHint

	await get_tree().create_timer(0.5).timeout
	Global.Particle_Spawner.emit_particle_scene(0, Vector2.ZERO, 0)
	await get_tree().create_timer(10).timeout
	Global.Screen_Hint.low_hp()
