extends Control
class_name HUDController

@onready var e_button = $MarginContainer/BoostControl/E_button

func _ready() -> void:
	if e_button:
		show_boost_available()

func show_boost_available() -> void:
	e_button.visible = true

func hide_boost_available() -> void:
	e_button.visible = false