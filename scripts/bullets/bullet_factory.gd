extends Node
class_name BulletFactory

const DEFAULT_POOL_SIZE := 20

## 对象池：场景路径 → 空闲子弹数组
var _pools: Dictionary = {}
## 所有活跃子弹
var active_bullets: Array[Bullet] = []


## 预生成一批子弹实例
func preload_pool(bullet_scene: PackedScene, amount: int = DEFAULT_POOL_SIZE) -> void:
	var key := bullet_scene.resource_path
	if not _pools.has(key):
		_pools[key] = []
	for _i in range(amount):
		_create_and_pool(bullet_scene, key)


## 发射子弹（传入 PackedScene）
func spawn(bullet_data: BulletData, bullet_scene: PackedScene, start_pos: Vector2, dir: Vector2, shooter: Node2D) -> Bullet:
	return _spawn_impl(bullet_data, bullet_scene.resource_path, start_pos, dir, shooter, bullet_scene)


## 发射子弹（传入场景路径字符串）
func spawn_by_path(bullet_data: BulletData, scene_path: String, start_pos: Vector2, dir: Vector2, shooter: Node2D) -> Bullet:
	return _spawn_impl(bullet_data, scene_path, start_pos, dir, shooter, null)


func _spawn_impl(bullet_data: BulletData, key: String, start_pos: Vector2, dir: Vector2, shooter: Node2D, fallback_scene: PackedScene = null) -> Bullet:
	if not _pools.has(key):
		_pools[key] = []

	var pool: Array = _pools[key]
	var bullet: Bullet

	if pool.is_empty():
		var scene := fallback_scene if fallback_scene else load(key) as PackedScene
		bullet = scene.instantiate() as Bullet
		add_child(bullet)
	else:
		bullet = pool.pop_back() as Bullet

	bullet.activate(bullet_data, start_pos, dir, shooter)
	active_bullets.append(bullet)
	return bullet


## 回收子弹到对象池
func return_bullet(bullet: Bullet) -> void:
	if bullet in active_bullets:
		active_bullets.erase(bullet)

	var key := bullet.scene_file_path
	if key.is_empty():
		bullet.queue_free()
		return

	if not _pools.has(key):
		_pools[key] = []

	bullet.hide()
	bullet.set_process(false)
	_pools[key].push_back(bullet)


## 清除某一类型的所有子弹
func clear_all_bullets_of_type(bullet_scene: PackedScene) -> void:
	var key := bullet_scene.resource_path
	for b in active_bullets.duplicate():
		if b.scene_file_path == key:
			b.deactivate()
	if _pools.has(key):
		for b in _pools[key]:
			b.queue_free()
		_pools.erase(key)


func _create_and_pool(scene: PackedScene, key: String) -> void:
	var bullet := scene.instantiate() as Bullet
	bullet.hide()
	bullet.set_process(false)
	add_child(bullet)
	_pools[key].append(bullet)
