extends Node
class_name BulletFactory

## 对象池：场景路径 → 可用子弹数组
var _pools: Dictionary = {}

## 所有活跃子弹的引用（方便全局操作）
var active_bullets: Array[Bullet] = []

## 默认池容量
const DEFAULT_POOL_SIZE := 20

## 预生成一批子弹（可选，在场景加载时调用）
func preload_pool(bullet_scene: PackedScene, amount: int = DEFAULT_POOL_SIZE) -> void:
	var key = bullet_scene.resource_path
	if not _pools.has(key):
		_pools[key] = []
	for i in range(amount):
		var bullet = bullet_scene.instantiate() as Bullet
		bullet.hide()
		bullet.set_process(false)
		add_child(bullet)
		_pools[key].append(bullet)

## 生成默认子弹
func spawn_defoult(bullet_scene: PackedScene, start_pos: Vector2, dir: Vector2, speed: float) -> Bullet:
	var key = bullet_scene.resource_path
	if not _pools.has(key):
		_pools[key] = []
	
	var pool: Array = _pools[key]
	var bullet: Bullet = null
	
	if pool.is_empty():
		# 池中无空闲，新建实例
		bullet = bullet_scene.instantiate() as Bullet
		add_child(bullet)
	else:
		bullet = pool.pop_back() as Bullet
	
	# 初始化子弹
	bullet.activate(start_pos, dir, speed)
	active_bullets.append(bullet)
	return bullet

## 回收子弹（由 Bullet.deactivate 调用，或手动归还）
func return_bullet(bullet: Bullet) -> void:
	if bullet in active_bullets:
		active_bullets.erase(bullet)
	
	var key = bullet.scene_file_path  # 获得子弹所属的场景路径
	if key.is_empty():
		# 如果无法获取场景路径，直接移除节点（未使用场景实例化的子弹）
		bullet.queue_free()
		return
	
	if not _pools.has(key):
		_pools[key] = []
	
	# 重置状态并放回池中
	bullet.hide()
	bullet.set_process(false)
	_pools[key].push_back(bullet)

## 清除某一类型的所有子弹（例如切换关卡）
func clear_all_bullets_of_type(bullet_scene: PackedScene) -> void:
	var key = bullet_scene.resource_path
	# 回收所有活跃子弹
	for bullet in active_bullets.duplicate():
		if bullet.scene_file_path == key:
			bullet.deactivate()
	# 销毁池中剩余
	if _pools.has(key):
		for bullet in _pools[key]:
			bullet.queue_free()
		_pools.erase(key)
