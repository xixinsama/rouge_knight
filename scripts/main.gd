extends Node2D
## 这里不必放什么

var spwan_pos: Vector2 = Vector2(160, 128)

const FIRE_BALL_BULLETS = preload("uid://6i0ko5avqu7")

func _ready() -> void:
	# 给GLobal 赋值
	Global.Floating_Texts = %FloatingTexts
	Global.Bullet_Factory = $BulletFactory
	Global.Particle_Spawner = $ParticleSpawner
	Global.UI_Layer = $UI
	Global.Screen_Hint = $UI/ScreenHint
	
	
	#Global.Path_Finder = $Map/AstarFindPath
	Global.draw_path = %PathDrawer
	Global.Layer_Manager = $LayerManager

	Global.Bullet_Factory.preload_pool(FIRE_BALL_BULLETS)
	var test_data := BulletData.new()
	test_data.bullet_type = BulletData.BulletType.NORMAL
	test_data.initial_speed = 100.0
	test_data.max_speed = 300.0
	Global.Bullet_Factory.spawn(test_data, FIRE_BALL_BULLETS, spwan_pos, Vector2(1, 0), null)

	# 设置弹反区域归属
	($"player弹反" as HitboxComponent).parry_owner = $"演示用Player"
	($"enemy弹反" as HitboxComponent).parry_owner = $"GodotEnemy"
	#var timer: Timer = Timer.new()
	#timer.wait_time = 12
	#timer.autostart = true
	#add_child(timer)
	#timer.timeout.connect(Global.Particle_Spawner.emit_particle_scene.bind(0, Vector2.ZERO, 0))
	#await get_tree().create_timer(0.5).timeout
	#Global.Particle_Spawner.emit_particle_scene(0, Vector2.ZERO, 0)
	# await get_tree().create_timer(10).timeout
	# Global.Screen_Hint.low_hp()
