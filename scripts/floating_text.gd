@tool
extends Node2D
## 飘动字体
## 还有待优化，或许使用对象池
class_name FloatingText

@export var label: Label

var position_tween: Tween
var scale_tween: Tween
var ori_pos: Vector2

signal finish_tween(text_node: Node2D)

func display_damage_text(text: String = "null", flag: int = 0)-> void:
	if position_tween != null and position_tween.is_running():
		position_tween.kill()
	if scale_tween != null and scale_tween.is_running():
		scale_tween.kill()

	ori_pos = global_position
	label.text = text
	visible = true
	
	if flag == 0:
		position_tween = create_tween()
		scale_tween = create_tween()
		position_tween.tween_property(self, "global_position", global_position + Vector2.UP * 16, 0.3)
		scale_tween.tween_property(self, "scale", Vector2.ONE, 0.3)
		position_tween.tween_property(self, "global_position", global_position + Vector2.UP * 48, 0.3)
		scale_tween.tween_property(self,"scale", Vector2.ZERO, 0.4)
		finish_tween.emit(self)
		position_tween.tween_callback(queue_free)
	elif flag == 1:
		pass
	else:
		pass

## 重置
func reset_text() -> void:
	finish_tween.emit(self)
	visible = false
	global_position = ori_pos
	scale = Vector2.ONE
	label.text = ""
