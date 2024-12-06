extends Node
class_name LandingController

func process(delta: float):
	var parent = get_parent() as RocketController
	update_landing_pad_state(parent)

	if not parent.is_on_landing_pad:
		return

	# Check crash
	if parent.current_state != parent.State.CRASHED and is_critically_tipped(parent):
		parent.start_crash_sequence()
	# Check stable landing
	elif is_landing_stable(parent):
		parent.current_stable_time += delta
		if parent.current_stable_time >= parent.required_stable_time:
			handle_successful_landing(parent)

func update_landing_pad_state(parent: RocketController):
	var landing_pad = get_landing_pad(parent)
	parent.is_on_landing_pad = landing_pad != null

func get_landing_pad(parent: RocketController) -> Node:
	for body in parent.get_colliding_bodies():
		if "Goal" in body.get_groups():
			return body
	return null

func handle_successful_landing(parent: RocketController):
	var landing_pad = get_landing_pad(parent)
	if not landing_pad:
		return

	if landing_pad is TriggerPad:
		landing_pad.activate_pad()

	if landing_pad.has_method("get_next_level_path"):
		var next_level = landing_pad.get_next_level_path()
		if not next_level.is_empty():
			parent.level_finished.emit(next_level)

func is_critically_tipped(parent: RocketController) -> bool:
	return get_tilt_angle(parent) >= parent.critical_tipping_angle

func is_landing_stable(parent: RocketController) -> bool:
	var current_velocity = parent.linear_velocity.length()
	return is_upright(parent) and current_velocity <= parent.max_landing_velocity

func is_upright(parent: RocketController) -> bool:
	return get_tilt_angle(parent) <= parent.max_landing_angle

func get_tilt_angle(parent: RocketController) -> float:
	var up_direction = parent.global_transform.basis.y
	return rad_to_deg(acos(up_direction.dot(Vector3.UP)))
