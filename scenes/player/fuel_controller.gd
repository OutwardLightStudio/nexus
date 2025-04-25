extends Node3D
class_name FuelController

signal fuel_depleted
signal boost_fuel_consumed
signal fuel_changed(current: float, max_fuel: float)

@onready var parent: RocketController = get_parent() as RocketController

const FUEL_OUT_CRASH_DELAY = 5.0
var time_since_fuel_out: float = 0.0
var is_fuel_depleted: bool = false

# Fuel properties
var max_fuel: float = 100.0
var current_fuel: float = max_fuel:
	set(value):
		var old_value = current_fuel
		current_fuel = clamp(value, 0.0, max_fuel)
		if old_value != current_fuel:
			fuel_changed.emit(current_fuel, max_fuel)

func _ready():
	await get_tree().process_frame
	# Get max fuel from parent if set
	if parent and parent.max_fuel > 0:
		max_fuel = parent.max_fuel
		current_fuel = parent.current_fuel
	
	connect_refueling_pads()
	
	# Initial fuel state
	fuel_changed.emit(current_fuel, max_fuel)

func connect_refueling_pads():
	var refuel_pads = get_tree().get_nodes_in_group("refuel_pad")
	for pad in refuel_pads:
		if pad.has_signal("refuel_tick"):
			pad.refuel_tick.connect(_on_refuel_tick)

func process(delta: float):
	# Skip processing if already crashed or transitioning
	if parent.current_state in [parent.State.CRASHED, parent.State.TRANSITIONING]:
		return
		
	# Process fuel consumption
	if parent.is_thrusting:
		reduce_fuel(parent.fuel_decrease * delta)
	
	# Handle fuel depletion
	handle_fuel_depletion(delta)

func handle_fuel_depletion(delta: float):
	if current_fuel <= 0:
		if not is_fuel_depleted:
			is_fuel_depleted = true
			fuel_depleted.emit()
		
		time_since_fuel_out += delta
		if time_since_fuel_out >= FUEL_OUT_CRASH_DELAY:
			parent.start_crash_sequence()

func reduce_fuel(amount: float):
	current_fuel -= amount

func add_fuel(amount: float):
	current_fuel += amount

func try_consume_boost_fuel() -> bool:
	if current_fuel >= parent.boost_fuel_cost:
		reduce_fuel(parent.boost_fuel_cost)
		boost_fuel_consumed.emit()
		return true
	
	return false

func _on_refuel_tick(amount: float):
	add_fuel(amount)
	
func get_fuel_percentage() -> float:
	return current_fuel / max_fuel
