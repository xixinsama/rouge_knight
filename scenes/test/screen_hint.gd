extends TextureRect
class_name ScreenHint

const FREEZE_EFFECT = preload("uid://dnki3o367uyjo")
const LOW_HEALTH_VIGNETTE = preload("uid://cw6yiv674yn05")

func _ready() -> void:
	self.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	# self.custom_minimum_size = Vector2(1280, 720)
	self.set_anchors_preset(Control.PRESET_CENTER)


## 为 TextureRect 播放一个“放大闪烁”提示动画
## 参数说明：
## - self: 目标控件，需要预先设置好纹理，并使其初始位置和大小适配屏幕（例如锚点全铺或设为中心）
## - start_scale: 起始缩放比例（例如 Vector2(0.2, 0.2)）
## - fade_in_duration: 放大并渐显的时长（秒）
## - hold_duration: 完全显示后的停留时长（秒）
## - fade_out_duration: 渐隐（变淡）的时长（秒）
func screen_prompt_animation(
	image: Texture,
	start_scale: Vector2 = Vector2(1.1, 1.1),
	fade_in_duration: float = 0.4,
	hold_duration: float = 0.2,
	fade_out_duration: float = 0.3
) -> void:
	# 如果已有正在执行的动画，先停止并重置控件状态
	if self.has_meta("current_tween"):
		var old_tween: Tween = self.get_meta("current_tween")
		if old_tween and old_tween.is_valid():
			old_tween.kill()
	
	self.texture = image
	# 确保缩放中心在矩形中心（避免放大时偏离）
	self.pivot_offset = self.size / 2.0
	
	# 重置初始状态：小尺寸、完全透明
	self.scale = start_scale
	self.modulate.a = 0.0
	
	# 创建新的 Tween 并存储为元数据，防止被垃圾回收以及便于后续管理
	var tween := create_tween()
	self.set_meta("current_tween", tween)
	
	# 第一部：放大到原始尺寸，同时从不透明变为完全可见（alpha 0 -> 1）
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), fade_in_duration).set_ease(Tween.EASE_IN)
	tween.parallel().tween_property(self, "modulate:a", 1.0, fade_in_duration)
	tween.tween_property(self, "scale", Vector2.ONE, fade_in_duration / 2).set_ease(Tween.EASE_OUT)
	# 等待停留时间
	tween.tween_interval(hold_duration)
	
	# 第二步：淡出（alpha 1 -> 0），变淡
	tween.tween_property(self, "modulate:a", 0.0, fade_out_duration)
	
	# 可选：动画结束后清除元数据（避免引用残留）
	tween.finished.connect(
		func():
			if self.get_meta("current_tween") == tween:
				self.remove_meta("current_tween")
	, CONNECT_ONE_SHOT)

func low_hp():
	screen_prompt_animation(LOW_HEALTH_VIGNETTE)
