extends Button

signal pressed_boost
signal released_boost

@onready var sprite = $Sprite2D

# Visual feedback properties
var normal_scale = Vector2(1.0, 1.0)
var pressed_scale = Vector2(0.9, 0.9)
var normal_modulate = Color(1, 1, 1, 1)
var pressed_modulate = Color(0.8, 0.8, 0.8, 1)

func _ready():
	# Configure the button to be transparent but clickable
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	# Connect button signals
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)

func _on_button_down():
	# Visual feedback when pressed
	sprite.scale = pressed_scale
	sprite.modulate = pressed_modulate
	emit_signal("pressed_boost")

func _on_button_up():
	# Return to normal appearance when released
	sprite.scale = normal_scale
	sprite.modulate = normal_modulate
	emit_signal("released_boost")