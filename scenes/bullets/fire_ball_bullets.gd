extends Bullet
class_name FireBall

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox_component: HitboxComponent = $HitboxComponent


func _ready() -> void:
	hitbox_component.hit.connect(deactivate.unbind(1))
	body_entered.connect(_on_body_entered)
	tree_entered.connect(func(): hitbox_component.active = true)
	animated_sprite_2d.play(&"bullet_0")

func shoot(bullet_data: BulletData, start_pos: Vector2, dir: Vector2, shooter: Node2D = null) -> void:
	activate(bullet_data, start_pos, dir, shooter)


func _on_body_entered(body: Node2D) -> void:
	if body is TileMapLayer:
		deactivate()
