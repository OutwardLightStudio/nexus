extends Node3D
class_name FuelController

@onready var fuel_slider: VSlider = $FuelSlider

signal fuel_depleted
signal boost_requested

func setup_fuel(max_fuel: float, current_fuel: float):
	fuel_slider.max_value = max_fuel
	fuel_slider.value = current_fuel
	fuel_slider.editable = false

func process(delta: float):
	var parent = get_parent() as RocketController
	if parent.thrust_active:
		parent.current_fuel -= parent.fuel_decrease * delta
		if parent.current_fuel <= 0:
			parent.current_fuel = 0
			parent.thrust_active = false
			emit_signal("fuel_depleted")

	if Input.is_action_just_pressed("boost_thrust") and parent.current_fuel >= parent.boost_fuel_cost:
		emit_signal("boost_requested")
