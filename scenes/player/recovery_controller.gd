extends Node
class_name RecoveryController

@onready var parent: RocketController = get_parent() as RocketController

const RECOVERY_MAX_TIME = 2.5
var time_since_critical_tilt: float = 0.0
var was_critically_tilted: bool = false

func _ready():
	await get_tree().process_frame
	connect_signals()

func connect_signals():
	if parent and parent.stability:
		parent.stability.connect("tilt_changed", self._on_tilt_changed)

func process(delta: float):
	if parent.current_state in [parent.State.CRASHED, parent.State.TRANSITIONING]:
		return
	
	check_tilt_and_crash(delta)

func _on_tilt_changed(tilt: float):
	check_tilt_and_crash(get_physics_process_delta_time())

func check_tilt_and_crash(delta: float):
	var is_critically_tilted = parent.tilt_angle >= parent.critical_tipping_angle
	
	if is_critically_tilted:
		time_since_critical_tilt += delta
		
		if time_since_critical_tilt >= RECOVERY_MAX_TIME:
			parent.start_crash_sequence()
	else:
		time_since_critical_tilt = 0.0

	was_critically_tilted = is_critically_tilted
