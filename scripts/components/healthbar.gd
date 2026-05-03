## 血条 — 绑定目标节点的 HealthComponent，实时同步血量到 TextureProgressBar
## 并产生掉血特效：白色方块依次落下淡出
extends TextureProgressBar
class_name HealthBar

## 持有 HealthComponent 的目标节点
@export var target: Node2D:
	set(v):
		target = v
		if is_inside_tree():
			_bind()

## 特效参数
@export var fall_distance: float = 50.0      # 下落距离（像素）
@export var fall_duration: float = 0.6       # 下落动画时长（秒）
@export var fade_duration: float = 0.5       # 淡出时长（秒）
@export var base_delay: float = 0.02         # 相邻方块的延迟间隔（最右边无延迟，向左递增）

var _health: HealthComponent
var _last_health: int = 0                    # 记录上一次血量，用于计算掉血量

# 缓存白色纹理
var _white_texture: Texture2D = null
var rect: Rect2

func _ready() -> void:
	await get_tree().create_timer(0.1).timeout
	_bind()

	rect = get_global_rect()
	print("HealthBar rect: ", rect)


func _bind() -> void:
	_disconnect_old()

	if not target:
		return

	_health = _find_health(target)
	if not _health:
		return

	_health.health_changed.connect(_on_health_changed)
	max_value = _health.max_health
	value = _health.current_health
	_last_health = _health.current_health


func _disconnect_old() -> void:
	if _health and _health.health_changed.is_connected(_on_health_changed):
		_health.health_changed.disconnect(_on_health_changed)
	_health = null


func _find_health(node: Node2D) -> HealthComponent:
	for child in node.get_children():
		if child is HealthComponent:
			return child
	return null


func _on_health_changed(current: int, _max: int) -> void:
	var damage = _last_health - current
	if damage > 0:
		value = current
		_spawn_damage_squares(damage)
		_last_health = current
	elif current > _last_health:
		value = current
		_last_health = current


## 生成掉血特效 — 白色方块从掉血区域右端开始，向左紧密排列，无间隙
func _spawn_damage_squares(damage: int) -> void:
	if damage <= 0 or not is_inside_tree():
		return

	var bar_width: float = rect.size.x
	var bar_height: float = rect.size.y
	if bar_width <= 0 or bar_height <= 0:
		return

	# 每个方块宽度 = 血条总宽 / 最大血量，自动适配，1 HP 对应 1 个方块
	var box_width: float = bar_width / max_value

	# 掉血区域右边界：掉血前红条末端位置
	var depleted_right: float = rect.position.x + bar_width * (float(_last_health) / max_value)
	# 掉血区域左边界：向右减去 damage 个方块宽
	var depleted_left: float = depleted_right - box_width * damage

	if not _white_texture:
		_white_texture = _create_white_texture()

	for i in range(damage):
		var square = Sprite2D.new()
		square.texture = _white_texture
		square.centered = false
		# 从左到右紧密排列，depleted_left + i * box_width 保证无间隙
		square.position = Vector2(depleted_left + i * box_width, rect.position.y)
		square.scale = Vector2(box_width, bar_height)

		get_parent().add_child(square)

		var fall_vector = Vector2(0, fall_distance)
		# 最右边（满血端）先落下，向左延迟递增
		var delay = base_delay * (damage - 1 - i)

		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(square, "position", square.position + fall_vector, fall_duration)\
			 .set_delay(delay).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(square, "modulate:a", 0.0, fade_duration)\
			 .set_delay(delay).set_ease(Tween.EASE_IN)

		tween.finished.connect(square.queue_free, CONNECT_ONE_SHOT)


## 创建一个 1x1 纯白色的纹理（用于缩放为任意大小）
func _create_white_texture() -> Texture2D:
	var img = Image.create(1, 1, false, Image.FORMAT_RGBA8)
	img.set_pixel(0, 0, Color.WHITE)
	return ImageTexture.create_from_image(img)
