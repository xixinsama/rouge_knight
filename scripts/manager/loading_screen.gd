extends Node

signal progress_changed(progress)
signal load_finished
var loading_screen: PackedScene = null
var loaded_resource: PackedScene
var scene_path: String
var progress: Array = []
var use_sub_threads: bool = true

func _ready() -> void:
	set_process(false)

func Load_scene(_scene_path: String) -> void:
	scene_path = _scene_path
	var new_load_screen = loading_screen.instantiate()
	add_child(new_load_screen)
	progress_changed.connect(new_load_screen._on_progress_changed)
	load_finished.connect(new_load_screen._on_load_finished)
	
