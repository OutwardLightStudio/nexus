extends Node
class_name LandingController

signal successful_landing
signal landing_pad_detected(on_pad: bool)

@onready var parent: RocketController = get_parent() as RocketController

func _ready():
	await get_tree().process_frame
	connect_signals()

func connect_signals():
	if parent and parent.stability:
		parent.stability.connect("tilt_changed", self._on_tilt_changed)

func process(delta: float):
	update_landing_pad_state()

	if not parent.is_on_landing_pad:
		return

	if is_landing_stable():
		parent.current_stable_time += delta
		if parent.current_stable_time >= parent.required_stable_time:
			handle_successful_landing()
	else:
		parent.current_stable_time = 0.0

func update_landing_pad_state():
	var landing_pad = get_landing_pad()
	var on_pad = landing_pad != null
	if on_pad != parent.is_on_landing_pad:
		parent.is_on_landing_pad = on_pad
		landing_pad_detected.emit(on_pad)

func get_landing_pad() -> Node:
	for body in parent.get_colliding_bodies():
		if "Goal" in body.get_groups():
			return body
	return null

func handle_successful_landing():
	var landing_pad = get_landing_pad()
	if not landing_pad:
		return

	if landing_pad is TriggerPad:
		landing_pad.activate_pad()
		
	successful_landing.emit()

func is_landing_stable() -> bool:
	var current_velocity = parent.linear_velocity.length()
	return parent.tilt_angle <= parent.max_landing_angle and current_velocity <= parent.max_landing_velocity

func _on_tilt_changed(tilt: float):
	if not parent.is_on_landing_pad:
		return

	if tilt >= parent.critical_tipping_angle:
		parent.start_crash_sequence()
