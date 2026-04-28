extends Node2D
## 这里不必放什么

func _ready() -> void:
	# 给GLobal 赋值
	Global.Bullet_Factory = $BulletFactory
	Global.Particle_Spawner = $ParticleSpawner
	Global.UI_Layer = $UI
	Global.Screen_Hint = $UI/ScreenHint
	Global.Path_Finder = $"Map/AstarFindPath"
	Global.draw_path = $Node2D

	var timer: Timer = Timer.new()
	timer.wait_time = 12
	timer.autostart = true
	add_child(timer)
	timer.timeout.connect(Global.Particle_Spawner.emit_particle_scene.bind(0, Vector2.ZERO, 0))
	#await get_tree().create_timer(0.5).timeout
	#Global.Particle_Spawner.emit_particle_scene(0, Vector2.ZERO, 0)
	await get_tree().create_timer(10).timeout
	Global.Screen_Hint.low_hp()
