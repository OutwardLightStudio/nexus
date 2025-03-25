extends Control
class_name TouchControls

signal thrust_pressed
signal thrust_released
signal rotate_left_pressed
signal rotate_left_released
signal rotate_right_pressed
signal rotate_right_released

@onready var thrust_button = $VBoxContainer/ThrustButton
@onready var rotate_left_button = $VBoxContainer/RotationContainer/RotateLeftButton
@onready var rotate_right_button = $VBoxContainer/RotationContainer/RotateRightButton

# Keep track of button states
var thrust_active = false
var rotate_left_active = false
var rotate_right_active = false

# Colors
var button_normal_color = Color("#6b6b6b")
var rotate_normal_color = Color("#5d5d5d")
var button_pressed_color = Color("#8c8c8c")
var background_color = Color("#44444480") # With 50% transparency

func _ready():
	# Connect button signals
	thrust_button.button_down.connect(_on_thrust_button_pressed)
	thrust_button.button_up.connect(_on_thrust_button_released)
	rotate_left_button.button_down.connect(_on_rotate_left_button_pressed)
	rotate_left_button.button_up.connect(_on_rotate_left_button_released)
	rotate_right_button.button_down.connect(_on_rotate_right_button_pressed)
	rotate_right_button.button_up.connect(_on_rotate_right_button_released)
	
	# Set initial appearance
	thrust_button.add_theme_color_override("icon_normal_color", button_normal_color)
	thrust_button.add_theme_color_override("icon_pressed_color", button_pressed_color)
	rotate_left_button.add_theme_color_override("icon_normal_color", rotate_normal_color)
	rotate_left_button.add_theme_color_override("icon_pressed_color", button_pressed_color)
	rotate_right_button.add_theme_color_override("icon_normal_color", rotate_normal_color)
	rotate_right_button.add_theme_color_override("icon_pressed_color", button_pressed_color)

# Handle touch input events for simultaneous button detection
func _input(event):
	if event is InputEventScreenTouch or event is InputEventScreenDrag:
		var touch_position = event.position
		
		# Check if touch is on this control
		if get_global_rect().has_point(touch_position):
			var local_pos = touch_position - global_position
			
			# Check each button individually
			if thrust_button.get_global_rect().has_point(touch_position):
				if not thrust_active and event is InputEventScreenTouch and event.pressed:
					_on_thrust_button_pressed()
				elif thrust_active and event is InputEventScreenTouch and not event.pressed:
					_on_thrust_button_released()
			elif not thrust_button.get_global_rect().has_point(touch_position) and thrust_active and event is InputEventScreenTouch and not event.pressed:
				_on_thrust_button_released()
				
			if rotate_left_button.get_global_rect().has_point(touch_position):
				if not rotate_left_active and event is InputEventScreenTouch and event.pressed:
					_on_rotate_left_button_pressed()
				elif rotate_left_active and event is InputEventScreenTouch and not event.pressed:
					_on_rotate_left_button_released()
			elif not rotate_left_button.get_global_rect().has_point(touch_position) and rotate_left_active and event is InputEventScreenTouch and not event.pressed:
				_on_rotate_left_button_released()
				
			if rotate_right_button.get_global_rect().has_point(touch_position):
				if not rotate_right_active and event is InputEventScreenTouch and event.pressed:
					_on_rotate_right_button_pressed()
				elif rotate_right_active and event is InputEventScreenTouch and not event.pressed:
					_on_rotate_right_button_released()
			elif not rotate_right_button.get_global_rect().has_point(touch_position) and rotate_right_active and event is InputEventScreenTouch and not event.pressed:
				_on_rotate_right_button_released()

func _on_thrust_button_pressed():
	thrust_active = true
	thrust_button.button_pressed = true
	Input.action_press("thrust")
	emit_signal("thrust_pressed")

func _on_thrust_button_released():
	thrust_active = false
	thrust_button.button_pressed = false
	Input.action_release("thrust")
	emit_signal("thrust_released")

func _on_rotate_left_button_pressed():
	rotate_left_active = true
	rotate_left_button.button_pressed = true
	Input.action_press("rotate_left")
	emit_signal("rotate_left_pressed")

func _on_rotate_left_button_released():
	rotate_left_active = false
	rotate_left_button.button_pressed = false
	Input.action_release("rotate_left")
	emit_signal("rotate_left_released")

func _on_rotate_right_button_pressed():
	rotate_right_active = true
	rotate_right_button.button_pressed = true
	Input.action_press("rotate_right")
	emit_signal("rotate_right_pressed")

func _on_rotate_right_button_released():
	rotate_right_active = false
	rotate_right_button.button_pressed = false
	Input.action_release("rotate_right")
	emit_signal("rotate_right_released")

func show_controls():
	visible = true

func hide_controls():
	visible = false

# Detect if running on mobile device
func is_mobile_device() -> bool:
	return OS.get_name() == "Android" or OS.get_name() == "iOS"
