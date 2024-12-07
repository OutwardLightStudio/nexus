extends Node
class_name StabilityController

signal tilt_changed(tilt: float)

@onready var parent: RocketController = get_parent() as RocketController

func _ready():
	await get_tree().process_frame
	if not parent:
		push_error("StabilityController: Failed to get parent RocketController")
		return

func process(_delta: float):
	if not parent:
		return
		
	if parent.current_state in [parent.State.CRASHED, parent.State.TRANSITIONING]:
		return
	
	update_tilt()

func update_tilt():
	var tilt = get_tilt_angle()
	tilt_changed.emit(tilt)

func get_tilt_angle() -> float:
	var up_direction = parent.global_transform.basis.y
	return rad_to_deg(acos(up_direction.dot(Vector3.UP)))
