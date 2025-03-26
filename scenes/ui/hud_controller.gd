extends Control
class_name HUDController

@onready var boost_button = $MarginContainer/LowerRightControl/boost_button
@onready var thrust_button = $MarginContainer/LowerRightControl/thrust_button
@onready var rotate_left_button = $MarginContainer/LowerLeftControl/rotate_left_button
@onready var rotate_right_button = $MarginContainer/LowerLeftControl/rotate_right_button
@onready var fuel_slider = $MarginContainer/FuelControls/FuelSlider

# Colors for fuel gauge gradient
var green_color: Color = Color(0, 1, 0)  # Green
var yellow_color: Color = Color(1, 1, 0)  # Yellow
var red_color: Color = Color(1, 0, 0)  # Red

func _ready() -> void:
	if boost_button:
		show_boost_available()
		boost_button.pressed.connect(_on_boost_button_down)
	
	if thrust_button:
		thrust_button.button_down.connect(_on_thrust_button_down)
		thrust_button.button_up.connect(_on_thrust_button_up)
	
	if rotate_left_button:
		rotate_left_button.button_down.connect(_on_rotate_left_button_down)
		rotate_left_button.button_up.connect(_on_rotate_left_button_up)
	
	if rotate_right_button:
		rotate_right_button.button_down.connect(_on_rotate_right_button_down)
		rotate_right_button.button_up.connect(_on_rotate_right_button_up)

func _on_boost_button_down() -> void:
	# Send boost press event
	var press_event = InputEventAction.new()
	press_event.action = "boost"
	press_event.pressed = true
	Input.parse_input_event(press_event)
	
	# Send boost release event immediately after
	var release_event = InputEventAction.new()
	release_event.action = "boost"
	release_event.pressed = false
	Input.parse_input_event(release_event)

func _on_thrust_button_down() -> void:
	var press_event = InputEventAction.new()
	press_event.action = "thrust"
	press_event.pressed = true
	Input.parse_input_event(press_event)

func _on_thrust_button_up() -> void:
	var release_event = InputEventAction.new()
	release_event.action = "thrust"
	release_event.pressed = false
	Input.parse_input_event(release_event)

func _on_rotate_left_button_down() -> void:
	var press_event = InputEventAction.new()
	press_event.action = "rotate_left"
	press_event.pressed = true
	Input.parse_input_event(press_event)

func _on_rotate_left_button_up() -> void:
	var release_event = InputEventAction.new()
	release_event.action = "rotate_left"
	release_event.pressed = false
	Input.parse_input_event(release_event)

func _on_rotate_right_button_down() -> void:
	var press_event = InputEventAction.new()
	press_event.action = "rotate_right"
	press_event.pressed = true
	Input.parse_input_event(press_event)

func _on_rotate_right_button_up() -> void:
	var release_event = InputEventAction.new()
	release_event.action = "rotate_right"
	release_event.pressed = false
	Input.parse_input_event(release_event)

func show_boost_available() -> void:
	if boost_button:
		boost_button.visible = true

func hide_boost_available() -> void:
	if boost_button:
		boost_button.visible = false

func update_fuel_display(current_fuel: float, max_fuel: float) -> void:
	if fuel_slider:
		fuel_slider.max_value = max_fuel
		fuel_slider.value = current_fuel
		fuel_slider.fill_mode = TextureProgressBar.FILL_BOTTOM_TO_TOP

		# Calculate fuel percentage and update color
		var fuel_percentage: float = current_fuel / max_fuel
		if fuel_percentage > 0.5:
			# Green to Yellow (50% to 100%)
			fuel_slider.modulate = green_color.lerp(yellow_color, (1.0 - fuel_percentage) * 2.0)
		else:
			# Yellow to Red (0% to 50%)
			fuel_slider.modulate = yellow_color.lerp(red_color, (0.5 - fuel_percentage) * 2.0)
