extends TextureRect
class_name ScreenHint

const FREEZE_EFFECT = preload("uid://dnki3o367uyjo")
const LOW_HEALTH_VIGNETTE = preload("uid://cw6yiv674yn05")

func _ready() -> void:
	texture = FREEZE_EFFECT
