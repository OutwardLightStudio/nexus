extends Control

@onready var resume_button = $CenterContainer/VBoxContainer/ResumeButton
@onready var restart_button = $CenterContainer/VBoxContainer/RestartButton
@onready var main_menu_button = $CenterContainer/VBoxContainer/MainMenuButton

func _ready():
	hide()
	resume_button.pressed.connect(_on_resume_pressed)
	restart_button.pressed.connect(_on_restart_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

func _unhandled_input(event):
	if event.is_action_pressed("pause"):
		if not visible:
			pause_game()
		else:
			unpause_game()
		get_viewport().set_input_as_handled()

func pause_game():
	show()
	get_tree().paused = true

func unpause_game():
	hide()
	get_tree().paused = false

func _on_resume_pressed():
	unpause_game()

func _on_restart_pressed():
	get_tree().paused = false  # Unpause before restarting
	get_tree().reload_current_scene()

func _on_main_menu_pressed():
	get_tree().paused = false  # Unpause before changing scenes
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")