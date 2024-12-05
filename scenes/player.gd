extends RigidBody3D
class_name RocketController

## Emitted when the rocket begins its crash sequence
signal crashed
## Emitted when the crash sequence is complete
signal crash_ended
## Emitted when a level is successfully completed
## [param next_level_path] Path to the next level scene
signal level_finished(next_level_path: String)
## Emitted when landing pad contact state changes
signal landing_state_changed(is_on_pad: bool)

#region Constants
enum State {
	FLYING,
	LANDING,
	CRASHED,
	TRANSITIONING
}

const MOVEMENT = {
	MIN_THRUST = 500,
	MAX_THRUST = 3000,
	DEFAULT_THRUST = 1000,
	DEFAULT_TORQUE = 100
}

const LANDING = {
	MAX_ANGLE = 60.0,        # Forgiving angle for landing attempts
	CRITICAL_ANGLE = 90,    # Only crash when almost completely tipped over
	STABLE_TIME = 0.5,       # Time required to register a successful landing
	MAX_VELOCITY = 50.0      # Maximum allowable landing velocity
}

const PHYSICS = {
	TIPPING_MULTIPLIER = 0.3,  # Controls self-righting force strength
	BASE_STABILITY = 150.0     # Base stability factor for landing
}

const UP_VECTOR := Vector3.UP
const THRUST_VECTOR := Vector3.UP

const RECOVERY = {
	MAX_RECOVERY_TIME = 0.5,  # Time allowed to recover from tipping over
	CHECK_INTERVAL = 0.1      # How often to update recovery status
}
#endregion

#region Exported Parameters
@export_group("Movement")
@export_range(MOVEMENT.MIN_THRUST, MOVEMENT.MAX_THRUST) 
var thrust: int = MOVEMENT.DEFAULT_THRUST
@export var torque: int = MOVEMENT.DEFAULT_TORQUE

@export_group("Landing")
@export_range(0, 90) var max_landing_angle: float = LANDING.MAX_ANGLE
@export_range(0, 90) var critical_tipping_angle: float = LANDING.CRITICAL_ANGLE
@export var required_stable_time: float = LANDING.STABLE_TIME
@export var max_landing_velocity: float = LANDING.MAX_VELOCITY

@export_group("Physics")
@export var tipping_torque_multiplier: float = PHYSICS.TIPPING_MULTIPLIER
@export var base_stability: float = PHYSICS.BASE_STABILITY

@export_group("Particles")
@export var booster_particles: GPUParticles3D
@export var right_booster_particles: GPUParticles3D
@export var left_booster_particles: GPUParticles3D
@export var explosion_particles: GPUParticles3D
@export var success_particles: GPUParticles3D

@export_group("Audio")
@export var explosion_sound: AudioStreamPlayer3D
@export var success_sound: AudioStreamPlayer3D
@export var bubbles_sound: AudioStreamPlayer3D
#endregion

#region State Variables
var current_state: State = State.FLYING
var current_stable_time: float = 0.0

var is_on_landing_pad: bool = false:
	set(value):
		if is_on_landing_pad != value:
			is_on_landing_pad = value
			landing_state_changed.emit(value)

var is_thrusting: bool = false:
	set(value):
		if is_thrusting != value:
			is_thrusting = value
			booster_particles.emitting = value
			bubbles_sound.playing = value

var time_since_critical_tilt: float = 0.0  # Tracks how long we've been tipped over
var last_tilt_check_time: float = 0.0      # Helps optimize tilt checking
#endregion

#region Lifecycle Methods
func _ready() -> void:
	_connect_signals()
	bubbles_sound.playing = false

func _physics_process(delta: float) -> void:
	if current_state == State.TRANSITIONING or current_state == State.CRASHED:
		return
		
	process_movement(delta)
	process_stability(delta)
	process_landing(delta)
	process_recovery(delta)

func _connect_signals() -> void:
	if not crashed.is_connected(_on_crashed):
		crashed.connect(_on_crashed)
	if not crash_ended.is_connected(_on_crash_ended):
		crash_ended.connect(_on_crash_ended)
	if not level_finished.is_connected(_on_level_finished):
		level_finished.connect(_on_level_finished)
	if not landing_state_changed.is_connected(_on_landing_state_changed):
		landing_state_changed.connect(_on_landing_state_changed)
#endregion

#region Signal Handlers
func _on_body_entered(body: Node) -> void:
	if current_state != State.CRASHED and "Hazard" in body.get_groups():
		start_crash_sequence()

func _on_crashed() -> void:
	current_state = State.CRASHED
	is_thrusting = false
	set_process(false)
	explosion_particles.emitting = true
	explosion_sound.playing = true
	
func _on_crash_ended() -> void:
	get_tree().reload_current_scene()

func _on_level_finished(next_level_path: String) -> void:
	current_state = State.TRANSITIONING
	set_process(false)
	success_particles.emitting = true
	success_sound.playing = true
	
	var tween = create_tween()
	tween.tween_interval(2)
	tween.tween_callback(func(): get_tree().change_scene_to_file(next_level_path))

func _on_landing_state_changed(on_pad: bool) -> void:
	if not on_pad:
		current_stable_time = 0.0
#endregion

#region State Changes
func start_crash_sequence() -> void:
	if current_state == State.CRASHED:
		return
	
	crashed.emit()
	var tween = create_tween()
	tween.tween_interval(2.5)
	tween.tween_callback(func(): crash_ended.emit())
#endregion

#region Movement
func process_movement(delta: float) -> void:
	handle_thrust(delta)
	handle_rotation(delta)

func handle_thrust(delta: float) -> void:
	var new_thrust_state = Input.is_action_pressed("boost")
	if new_thrust_state != is_thrusting:
		self.is_thrusting = new_thrust_state
	
	if is_thrusting:
		apply_central_force(basis.y * thrust * delta)

func handle_rotation(delta: float) -> void:
	var rotation_direction = Input.get_axis("rotate_right", "rotate_left")
	if rotation_direction != 0:
		var torque_amount = torque * delta * rotation_direction
		apply_torque(Vector3(0, 0, torque_amount))
	
	left_booster_particles.emitting = rotation_direction < 0
	right_booster_particles.emitting = rotation_direction > 0
#endregion

#region Stability
func process_stability(delta: float) -> void:
	if is_on_landing_pad:
		apply_tipping_forces(delta)

func apply_tipping_forces(delta: float) -> void:
	var tilt_angle = get_tilt_angle()
	if tilt_angle > max_landing_angle and tilt_angle < critical_tipping_angle:
		var tipping_torque = calculate_tipping_torque(tilt_angle, delta)
		apply_torque(Vector3(0, 0, tipping_torque))

func calculate_tipping_torque(tilt_angle: float, delta: float) -> float:
	var right_vector := global_transform.basis.x
	var tilt_direction := global_transform.basis.y.cross(UP_VECTOR)
	
	var tilt_factor = (tilt_angle - max_landing_angle) / \
					 (critical_tipping_angle - max_landing_angle)
	
	var base_factor = 1.0 - (base_stability / (tilt_angle + base_stability))
	return tilt_direction.dot(right_vector) * tipping_torque_multiplier * tilt_factor * base_factor * delta

func get_tilt_angle() -> float:
	var up_direction := global_transform.basis.y
	return rad_to_deg(acos(up_direction.dot(UP_VECTOR)))

func is_upright() -> bool:
	return get_tilt_angle() <= max_landing_angle

func is_critically_tipped() -> bool:
	return get_tilt_angle() >= critical_tipping_angle

func is_landing_stable() -> bool:
	var current_velocity = linear_velocity.length()
	return is_upright() and current_velocity <= max_landing_velocity
#endregion

#region Landing
func process_landing(delta: float) -> void:
	update_landing_pad_state()
	
	if not is_on_landing_pad:
		return
		
	if current_state != State.CRASHED and is_critically_tipped():
		start_crash_sequence()
	elif is_landing_stable():
		current_stable_time += delta
		if current_stable_time >= required_stable_time:
			handle_successful_landing()

func update_landing_pad_state() -> void:
	var landing_pad = get_landing_pad()
	self.is_on_landing_pad = landing_pad != null

func get_landing_pad() -> Node:
	for body in get_colliding_bodies():
		if "Goal" in body.get_groups():
			return body
	return null

func handle_successful_landing() -> void:
	var landing_pad = get_landing_pad()
	if not landing_pad:
		return
		
	if landing_pad is TriggerPad:
		landing_pad.activate_pad()
	
	if landing_pad.has_method("get_next_level_path"):
		var next_level = landing_pad.get_next_level_path()
		if not next_level.is_empty():
			level_finished.emit(next_level)
#endregion

#region Recovery
func process_recovery(delta: float) -> void:
	# Only update our check periodically to avoid unnecessary calculations
	last_tilt_check_time += delta
	if last_tilt_check_time < RECOVERY.CHECK_INTERVAL:
		return
	last_tilt_check_time = 0.0
	
	var current_tilt = get_tilt_angle()
	
	# If we're critically tipped and not on a landing pad
	if current_tilt >= critical_tipping_angle and not is_on_landing_pad:
		time_since_critical_tilt += delta
		
		# If we've been tipped too long, crash
		if time_since_critical_tilt >= RECOVERY.MAX_RECOVERY_TIME:
			start_crash_sequence()
	else:
		# Reset the timer if we're not critically tipped
		time_since_critical_tilt = 0.0
#endregion
