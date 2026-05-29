@tool
extends EditorPlugin

func _enter_tree() -> void:
	pass

func _exit_tree() -> void:
	pass

func _enable_plugin() -> void:
	add_autoload_singleton(&"LogManager", "res://addons/control_console/scripts/log_manager.gd")

func _disable_plugin() -> void:
	remove_autoload_singleton(&"LogManager")
