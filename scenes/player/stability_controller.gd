extends Node
class_name StabilityController

signal tilt_changed(tilt: float)

@onready var parent: RocketController = get_parent() as RocketController

# Recovery settings
const RECOVERY_MAX_TIME = 2.5  # Time window for recovery before crash
var time_since_critical_tilt: float = 0.0
var was_critically_tilted: bool = false

func _ready():
	await get_tree().process_frame
	if not parent:
		push_error("StabilityController: Failed to get parent RocketController")
		return

func process(delta: float):
	# Skip processing if in non-active states
	if parent.current_state in [parent.State.CRASHED, parent.State.TRANSITIONING]:
		return

	# Calculate current tilt
	var current_tilt = get_tilt_angle()
	tilt_changed.emit(current_tilt)
	
	# Store tilt in parent for other systems to reference
	parent.tilt_angle = current_tilt
	
	# Check for dangerous tilt situations
	var is_critically_tilted = current_tilt >= parent.critical_tipping_angle
	
	if is_critically_tilted:
		# Accumulate time spent in dangerous tilt
		time_since_critical_tilt += delta
		
		# Trigger crash if tilted too long and attempting to land
		if time_since_critical_tilt >= RECOVERY_MAX_TIME and parent.current_state == parent.State.LANDING:
			parent.start_crash_sequence()
	else:
		# Reset recovery timer when safe
		time_since_critical_tilt = 0.0
	
	was_critically_tilted = is_critically_tilted

func get_tilt_angle() -> float:
	var up_direction = parent.global_transform.basis.y
	return rad_to_deg(acos(up_direction.dot(Vector3.UP)))
