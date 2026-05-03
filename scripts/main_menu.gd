extends Node2D

@onready var line_edit: LineEdit = $CanvasLayer/Control/VBoxContainer/LineEdit
@onready var button: Button = $CanvasLayer/Control/VBoxContainer/Button

const MAIN_PATH := "res://scenes/main.tscn"

var seed_text: String = ""

func _ready() -> void:
	line_edit.text_submitted.connect(_on_text_submitted)
	button.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	# 生成16位随机种子，并显示
	if seed_text == "":
		pass
	# 加载主场景
	SceneLoader.load_scene(MAIN_PATH)

func _on_text_submitted(new_text: String) -> void:
	pass
