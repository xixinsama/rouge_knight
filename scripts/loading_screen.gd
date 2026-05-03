extends CanvasLayer

@onready var progress_bar: ProgressBar = $Control/ProgressBar
@onready var animation_player: AnimationPlayer = $AnimationPlayer

signal loading_screen_ready

func _ready() -> void:
	progress_bar.value = 0
	
	animation_player.play_backwards(&"switch")
	await animation_player.animation_finished
	# await get_tree().create_timer(0.5).timeout # 总之要等一下
	
	loading_screen_ready.emit()

func _on_progress_changed(progress: float) -> void:
	progress_bar.value = progress

func _on_load_finished() -> void:
	animation_player.play(&"switch")
	await animation_player.animation_finished
	queue_free()
