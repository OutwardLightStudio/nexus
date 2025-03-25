extends Button
class_name TouchButton

@export var icon_texture: Texture2D
@export var label_text: String = ""

# Button colors
var icon_normal_color: Color = Color(1, 1, 1)
var icon_pressed_color: Color = Color(1, 1, 1)

# Reference to the arrow icon
@onready var arrow_icon = $ArrowIcon
@onready var key_label = $KeyLabel

func _ready():
	# Configure the icon
	if icon_texture:
		arrow_icon.texture = icon_texture
	
	# Configure the label
	if label_text != "":
		key_label.text = label_text
	
	# Connect signals
	button_down.connect(_on_button_pressed)
	button_up.connect(_on_button_released)

func _on_button_pressed():
	# Change the color of the icon when pressed
	if arrow_icon:
		arrow_icon.modulate = icon_pressed_color

func _on_button_released():
	# Restore the icon color when released
	if arrow_icon:
		arrow_icon.modulate = icon_normal_color

func set_icon_colors(normal_color: Color, pressed_color: Color):
	icon_normal_color = normal_color
	icon_pressed_color = pressed_color
	if arrow_icon:
		arrow_icon.modulate = icon_pressed_color if is_pressed() else icon_normal_color
