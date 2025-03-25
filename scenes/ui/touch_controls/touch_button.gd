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
	pressed.connect(_on_button_pressed)
	released.connect(_on_button_released)

func _draw():
	# Draw button with rounded corners (8px radius)
	var style = get_theme_stylebox("normal")
	if style:
		# The button already has its style defined in the theme

func _on_button_pressed():
	# Change the color of the icon when pressed
	if arrow_icon:
		arrow_icon.modulate = icon_pressed_color

func _on_button_released():
	# Restore the icon color when released
	if arrow_icon:
		arrow_icon.modulate = icon_normal_color

func add_theme_color_override(property: String, color: Color):
	if property == "icon_normal_color":
		icon_normal_color = color
		if not button_pressed:
			arrow_icon.modulate = color
	elif property == "icon_pressed_color":
		icon_pressed_color = color
		if button_pressed:
			arrow_icon.modulate = color