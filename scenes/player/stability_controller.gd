extends Node
class_name StabilityController

func process(delta: float):
	var parent = get_parent() as RocketController
	if parent.is_on_landing_pad:
		apply_tipping_forces(delta)

func apply_tipping_forces(delta: float):
	var parent = get_parent() as RocketController
	var tilt_angle = get_tilt_angle(parent)
	if tilt_angle > parent.max_landing_angle and tilt_angle < parent.critical_tipping_angle:
		var tipping_torque = calculate_tipping_torque(parent, tilt_angle, delta)
		parent.apply_torque(Vector3(0, 0, tipping_torque))

func calculate_tipping_torque(parent: RocketController, tilt_angle: float, delta: float) -> float:
	var right_vector = parent.global_transform.basis.x
	var tilt_direction = parent.global_transform.basis.y.cross(Vector3.UP)
	var tilt_factor = (tilt_angle - parent.max_landing_angle) / (parent.critical_tipping_angle - parent.max_landing_angle)
	var base_factor = 1.0 - (parent.base_stability / (tilt_angle + parent.base_stability))
	return tilt_direction.dot(right_vector) * parent.tipping_torque_multiplier * tilt_factor * base_factor * delta

func get_tilt_angle(parent: RocketController) -> float:
	var up_direction = parent.global_transform.basis.y
	return rad_to_deg(acos(up_direction.dot(Vector3.UP)))
