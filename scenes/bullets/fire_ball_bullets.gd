extends Bullet
class_name FireBall

const sprite_animation_name: Array[StringName] = [&"bullet_0", &"bullet_1", &"bullet_2", &"bullet_3", &"bullet_4", &"bullet_5", &"bullet_6", &"bullet_7", &"bullet_8"]

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox_component: HitboxComponent = $HitboxComponent

func _ready() -> void:
	hitbox_component.hit.connect(self.deactivate.unbind(1)) ## 命中回收
	self.body_entered.connect(_on_body_entered)
	self.tree_entered.connect(func(): hitbox_component.active = true)
	animated_sprite_2d.play(&"bullet_0")
	

func shoot(type: int, start_pos: Vector2, dir: Vector2, spd: float):
	animated_sprite_2d.play(sprite_animation_name[clampi(type, 0, 8)])
	self.activate(start_pos, dir, spd)

## 撞墙回收
func _on_body_entered(body: Node2D):
	if body is TileMapLayer:
		self.deactivate()
