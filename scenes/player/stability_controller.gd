extends Node
class_name StabilityController

# Configuration Constants
const RECOVERY_MAX_TIME = 0.5
const RECOVERY_CHECK_INTERVAL = 0.1

# Variables to track tilt and recovery status
var time_since_critical_tilt: float = 0.0
var last_tilt_check_time: float = 0.0

func process(delta: float):
	var parent = get_parent() as RocketController
	parent.last_tilt_check_time += delta

	# Run tilt checks only at intervals to reduce processing overhead
	if parent.last_tilt_check_time >= RECOVERY_CHECK_INTERVAL:
		parent.last_tilt_check_time = 0.0
		_handle_tilt_check(parent, delta)
	
	if parent.is_on_landing_pad:
		apply_tipping_forces(delta)

func _handle_tilt_check(parent: RocketController, delta: float):
	"""
	Handles checking for critical tilt and initiating crash sequences if necessary.
	"""
	var tilt = get_tilt_angle(parent)
	
	# Check if the rocket is critically tipped while not on a landing pad
	if tilt >= parent.critical_tipping_angle and not parent.is_on_landing_pad:
		parent.time_since_critical_tilt += delta
		if parent.time_since_critical_tilt >= RECOVERY_MAX_TIME:
			parent.start_crash_sequence()
	else:
		parent.time_since_critical_tilt = 0.0

func apply_tipping_forces(delta: float):
	"""
	Applies torque to stabilize the rocket if it's on a landing pad.
	"""
	var parent = get_parent() as RocketController
	var tilt_angle = get_tilt_angle(parent)
	if tilt_angle > parent.max_landing_angle and tilt_angle < parent.critical_tipping_angle:
		var tipping_torque = calculate_tipping_torque(parent, tilt_angle, delta)
		parent.apply_torque(Vector3(0, 0, tipping_torque))

func calculate_tipping_torque(parent: RocketController, tilt_angle: float, delta: float) -> float:
	"""
	Calculates the torque needed to stabilize the rocket based on its tilt.
	"""
	var right_vector = parent.global_transform.basis.x
	var tilt_direction = parent.global_transform.basis.y.cross(Vector3.UP)
	var tilt_factor = (tilt_angle - parent.max_landing_angle) / (parent.critical_tipping_angle - parent.max_landing_angle)
	var base_factor = 1.0 - (parent.base_stability / (tilt_angle + parent.base_stability))
	return tilt_direction.dot(right_vector) * parent.tipping_torque_multiplier * tilt_factor * base_factor * delta

func get_tilt_angle(parent: RocketController) -> float:
	"""
	Returns the tilt angle of the rocket relative to the global UP vector.
	"""
	var up_direction = parent.global_transform.basis.y
	return rad_to_deg(acos(up_direction.dot(Vector3.UP)))
