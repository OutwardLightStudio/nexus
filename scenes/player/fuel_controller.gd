extends Node3D
class_name FuelController

@onready var fuel_slider: VSlider = $FuelSlider
@onready var parent: RocketController = get_parent() as RocketController

signal fuel_depleted
signal boost_requested

# Time to wait after fuel depletion before crashing
const FUEL_OUT_CRASH_DELAY = 5.0
var time_since_fuel_out: float = 0.0
var is_fuel_depleted: bool = false

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
	# Skip processing if already crashed or transitioning
	if parent.current_state in [parent.State.CRASHED, parent.State.TRANSITIONING]:
		return
		
	# Process fuel consumption
	if parent.is_thrusting:
		parent.current_fuel -= parent.fuel_decrease * delta
	
	# Clamp and update fuel values
	parent.current_fuel = clamp(parent.current_fuel, 0.0, parent.max_fuel)
	update_fuel_display(parent.current_fuel)
	
	# Handle fuel depletion
	if parent.current_fuel <= 0:
		if not is_fuel_depleted:
			is_fuel_depleted = true
			fuel_depleted.emit()
		
		# Start counting time since fuel ran out
		time_since_fuel_out += delta
		
		# Trigger crash sequence after delay
		if time_since_fuel_out >= FUEL_OUT_CRASH_DELAY:
			parent.start_crash_sequence()
	else:
		# Reset fuel depletion tracking if we somehow get more fuel
		is_fuel_depleted = false
		time_since_fuel_out = 0.0

	# Handle boost requests
	if Input.is_action_just_pressed("boost") and parent.current_fuel >= parent.boost_fuel_cost:
		boost_requested.emit()

func update_fuel_display(current_fuel: float):
	if fuel_slider:
		fuel_slider.value = current_fuel
