extends Node
class_name MovementController

signal boost_activated

@onready var parent: RocketController = get_parent() as RocketController
@onready var left_booster: GPUParticles3D = $BoosterBubblesLeft
@onready var right_booster: GPUParticles3D = $BoosterBubblesRight

func _ready():
	await get_tree().process_frame
	connect_signals()

func connect_signals():
	if parent and parent.fuel_controller:
		parent.fuel_controller.fuel_depleted.connect(_on_fuel_depleted)
		parent.fuel_controller.boost_requested.connect(_on_boost_requested)

func process(delta: float):
	if parent.current_state in [parent.State.CRASHED, parent.State.TRANSITIONING]:
		return
	
	handle_thrust(delta)
	handle_rotation(delta)

func handle_thrust(delta: float):
	# Update parent's thrusting state based on input
	parent.is_thrusting = Input.is_action_pressed("thrust") and parent.current_fuel > 0.0
	
	if parent.is_thrusting:
		apply_thrust(delta)
	
	if parent.boosting:
		apply_boost(delta)
	
	if Input.is_action_just_pressed("boost") and parent.current_fuel >= parent.boost_fuel_cost:
		parent.fuel_controller.emit_signal("boost_requested")
	
	if Input.is_action_just_released("boost") or parent.boosting:
		stop_thrust()

func apply_thrust(_delta: float):
	# Get current vertical velocity
	var current_velocity = parent.linear_velocity.length()
	
	# Calculate thrust force with dampening based on velocity
	var thrust_force = parent.thrust
	
	# Reduce thrust as we approach max velocity
	if current_velocity > 0:
		var velocity_ratio = current_velocity / parent.max_velocity
		thrust_force *= (1.0 - clamp(velocity_ratio * parent.thrust_dampening, 0.0, 0.9))
	
	# Apply the dampened thrust
	parent.apply_central_force(parent.global_transform.basis.y * thrust_force)
	parent.thrust_active = true

func apply_boost(_delta: float):
	# Similar dampening for boost
	var current_velocity = parent.linear_velocity.length()
	var boost_force = parent.boost_thrust
	
	if current_velocity > 0:
		var velocity_ratio = current_velocity / (parent.max_velocity * 1.5)  # Allow higher speed for boost
		boost_force *= (1.0 - clamp(velocity_ratio * parent.thrust_dampening, 0.0, 0.9))
	
	parent.apply_central_force(parent.global_transform.basis.y * boost_force)
	parent.thrust_active = false

func handle_rotation(delta: float):
	var rotation_direction = Input.get_axis("rotate_right", "rotate_left")
	if rotation_direction != 0:
		var torque_amount = parent.torque * delta * rotation_direction
		parent.apply_torque(Vector3(0, 0, torque_amount))
	
	# Update visual feedback for rotation via booster particle effects
	left_booster.emitting = rotation_direction < 0
	right_booster.emitting = rotation_direction > 0

func stop_thrust():
	parent.is_thrusting = false
	parent.thrust_active = false

func _on_fuel_depleted():
	stop_thrust()

func _on_boost_requested():
	if parent.current_fuel >= parent.boost_fuel_cost and not parent.boosting:
		activate_boost()
		boost_activated.emit()

func activate_boost():
	parent.apply_central_force(parent.global_transform.basis.y * parent.boost_thrust)
	parent.current_fuel -= parent.boost_fuel_cost
	parent.current_fuel = clamp(parent.current_fuel, 0.0, parent.max_fuel)
	parent.boosting = true
	parent.boost_timer = parent.boost_duration
