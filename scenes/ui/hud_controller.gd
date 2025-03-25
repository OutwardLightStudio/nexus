extends Control
class_name HUDController

@onready var fuel_slider = $MarginContainer/FuelControls/FuelSlider
@onready var touch_controls = $MarginContainer/TouchControls

# Colors for fuel gauge gradient
var green_color: Color = Color(0, 1, 0)  # Green
var yellow_color: Color = Color(1, 1, 0)  # Yellow
var red_color: Color = Color(1, 0, 0)  # Red

func _ready() -> void:
	# E button is now managed through touch_controls
	if touch_controls:
		show_boost_available()

func show_boost_available() -> void:
	if touch_controls:
		touch_controls.show_boost_button()

func hide_boost_available() -> void:
	if touch_controls:
		touch_controls.hide_boost_button()

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
