extends Node3D
class_name FuelController

@onready var fuel_slider: VSlider = $FuelSlider
@onready var parent: RocketController = get_parent() as RocketController

signal fuel_depleted
signal boost_requested

func _ready():
	await get_tree().process_frame
	if parent:
		setup_fuel(parent.max_fuel, parent.current_fuel)

func setup_fuel(max_fuel: float, current_fuel: float):
	if fuel_slider:
		fuel_slider.max_value = max_fuel
		fuel_slider.value = current_fuel
		fuel_slider.editable = false

func process(delta: float):
	parent.current_fuel -= parent.fuel_decrease * delta if parent.is_thrusting else 0
	if parent.current_fuel <= 0:
		parent.current_fuel = 0
		fuel_depleted.emit()

	if Input.is_action_just_pressed("boost") and parent.current_fuel >= parent.boost_fuel_cost:
		boost_requested.emit()
