extends Node2D

const CFG_00 = preload("res://scenes/enemies/configs/enemy_00_chaser.tres")
const CFG_01 = preload("res://scenes/enemies/configs/enemy_01_shooter.tres")
const CFG_02 = preload("res://scenes/enemies/configs/enemy_02_puncher.tres")
const CFG_03 = preload("res://scenes/enemies/configs/enemy_03_fast_chaser.tres")
const CFG_04 = preload("res://scenes/enemies/configs/enemy_04_ghost.tres")

func _ready() -> void:
	# 给GLobal 赋值
	Global.UI_Layer = $UI
	
	Global.Particle_Spawner = $ParticleSpawner
	Global.Enemy_Factory = $EnemyFactory
	Global.Bullet_Factory = $BulletFactory
	Global.Floating_Texts = %FloatingTexts
	
	Global.Screen_Hint = $UI/ScreenHint
	
	#Global.Path_Finder = $Map/AstarFindPath
	Global.draw_path = %PathDrawer
	Global.Layer_Manager = $LayerManager

	_spawn(CFG_04, Vector2(0, -150))


func _spawn(config: EnemyConfig, pos: Vector2) -> void:
	if Global.Enemy_Factory:
		Global.Enemy_Factory.spawn(config, pos)
