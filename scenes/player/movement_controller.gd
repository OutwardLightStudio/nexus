extends Node
class_name MovementController

func process(delta: float):
	var parent = get_parent() as RocketController
	var rb = parent
	var current_fuel = parent.current_fuel
	var thrust = parent.thrust
	var torque = parent.torque
	var boosting = parent.boosting
	var boost_thrust = parent.boost_thrust

	var new_thrust_state = Input.is_action_pressed("boost")
	if new_thrust_state != parent.is_thrusting:
		parent.is_thrusting = new_thrust_state

	if parent.is_thrusting and current_fuel > 0.0 and not boosting:
		rb.apply_central_force(rb.basis.y * thrust * delta)
		parent.thrust_active = true
	elif boosting:
		rb.apply_central_force(rb.basis.y * boost_thrust * delta)
		parent.thrust_active = false
	elif Input.is_action_just_released("boost") or boosting:
		parent.thrust_active = false

	if Input.is_action_just_pressed("boost_thrust") and current_fuel >= parent.boost_fuel_cost:
		parent.activate_boost()

	handle_rotation(delta, rb, torque)

func handle_rotation(delta: float, rb: RigidBody3D, torque: float):
	var parent = get_parent() as RocketController
	var rotation_direction = Input.get_axis("rotate_right", "rotate_left")
	if rotation_direction != 0:
		var torque_amount = torque * delta * rotation_direction
		rb.apply_torque(Vector3(0, 0, torque_amount))

	# Update booster side particles
	var left_booster = $BoosterBubblesLeft
	var right_booster = $BoosterBubblesRight
	left_booster.emitting = rotation_direction < 0
	right_booster.emitting = rotation_direction > 0

func stop_thrust():
	var parent = get_parent() as RocketController
	parent.is_thrusting = false
	parent.thrust_active = false
