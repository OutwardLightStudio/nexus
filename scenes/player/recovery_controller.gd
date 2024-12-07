extends Node
class_name RecoveryController

const RECOVERY_MAX_TIME = 0.5
const RECOVERY_CHECK_INTERVAL = 0.1

func process(delta: float):
	var parent = get_parent() as RocketController
	parent.last_tilt_check_time += delta
	if parent.last_tilt_check_time < RECOVERY_CHECK_INTERVAL:
		return
	parent.last_tilt_check_time = 0.0

	var tilt = get_tilt_angle(parent)
	if tilt >= parent.critical_tipping_angle and not parent.is_on_landing_pad:
		parent.time_since_critical_tilt += delta
		if parent.time_since_critical_tilt >= RECOVERY_MAX_TIME:
			parent.start_crash_sequence()
	else:
		parent.time_since_critical_tilt = 0.0

func get_tilt_angle(parent: RocketController) -> float:
	var up_direction = parent.global_transform.basis.y
	return rad_to_deg(acos(up_direction.dot(Vector3.UP)))
