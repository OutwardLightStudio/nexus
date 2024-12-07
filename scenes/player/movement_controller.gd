extends Node
class_name MovementController

signal boost_activated

@onready var parent: RocketController = get_parent() as RocketController

# Boost-related state
var boost_timer: float = 0.0
var is_boost_active: bool = false

func _ready() -> void:
	await get_tree().process_frame
	connect_signals()

func connect_signals() -> void:
	if parent and parent.fuel_controller:
		parent.fuel_controller.fuel_depleted.connect(_on_fuel_depleted)
		parent.fuel_controller.boost_fuel_consumed.connect(_on_boost_fuel_consumed)

func process(delta: float) -> void:
	if parent.current_state in [parent.State.CRASHED, parent.State.TRANSITIONING]:
		return
	
	process_thrust(delta)
	process_boost(delta)
	process_rotation(delta)

# Primary movement processing methods
func process_thrust(delta: float) -> void:
	if not is_boost_active:
		var should_thrust = Input.is_action_pressed("thrust") and parent.current_fuel > 0.0
		if parent.is_thrusting != should_thrust:
			parent.is_thrusting = should_thrust
			parent.effects.update_thrust_effects(should_thrust)
		
		if parent.is_thrusting:
			apply_thrust_force(delta)

func process_boost(delta: float) -> void:
	# Handle boost activation
	if Input.is_action_just_pressed("boost") and can_activate_boost():
		activate_boost()
	
	# Process active boost
	if is_boost_active:
		apply_boost_force(delta)
		update_boost_timer(delta)

func process_rotation(delta: float) -> void:
	var rotation_direction = Input.get_axis("rotate_right", "rotate_left")
	if rotation_direction != 0:
		apply_rotation(rotation_direction, delta)
	
	parent.effects.update_rotation_effects(rotation_direction)

# Thrust-related methods
func apply_thrust_force(delta: float) -> void:
	var thrust_force = calculate_dampened_force(
		parent.thrust,
		parent.max_velocity,
		parent.linear_velocity.length()
	)
	
	apply_force(thrust_force)
	parent.thrust_active = true

# Boost-related methods
func can_activate_boost() -> bool:
	return (
		parent.current_fuel >= parent.boost_fuel_cost
		and not is_boost_active
		and not parent.is_thrusting
	)

func activate_boost() -> void:
	is_boost_active = true
	parent.boosting = true
	boost_timer = parent.boost_duration
	
	consume_boost_fuel()
	boost_activated.emit()

func apply_boost_force(delta: float) -> void:
	var boost_force = calculate_dampened_force(
		parent.boost_thrust,
		parent.max_velocity * 1.5,  # Allow higher speed for boost
		parent.linear_velocity.length()
	)
	
	apply_force(boost_force)
	parent.thrust_active = false

func update_boost_timer(delta: float) -> void:
	boost_timer -= delta
	if boost_timer <= 0:
		deactivate_boost()

func deactivate_boost() -> void:
	is_boost_active = false
	parent.boosting = false
	boost_timer = 0.0
	parent.thrust_active = false

func consume_boost_fuel() -> void:
	parent.current_fuel -= parent.boost_fuel_cost
	parent.current_fuel = clamp(parent.current_fuel, 0.0, parent.max_fuel)

# Rotation-related methods
func apply_rotation(rotation_direction: float, delta: float) -> void:
	var torque_amount = parent.torque * delta * rotation_direction
	parent.apply_torque(Vector3(0, 0, torque_amount))


# Shared physics helper methods
func calculate_dampened_force(base_force: float, max_speed: float, current_speed: float) -> float:
	var dampened_force = base_force
	
	if current_speed > 0:
		var velocity_ratio = current_speed / max_speed
		dampened_force *= (1.0 - clamp(velocity_ratio * parent.thrust_dampening, 0.0, 0.9))
	
	return dampened_force

func apply_force(force: float) -> void:
	parent.apply_central_force(parent.global_transform.basis.y * force)

# Signal handlers
func _on_fuel_depleted() -> void:
	parent.is_thrusting = false
	parent.thrust_active = false
	
	if is_boost_active:
		deactivate_boost()

func _on_boost_fuel_consumed() -> void:
	activate_boost()
	boost_activated.emit()
