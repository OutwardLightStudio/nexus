extends RigidBody3D

# Signals for state transitions and game events
signal crash_started
signal crash_completed
signal level_completed(next_level: String)
signal landing_state_changed(is_on_pad: bool)

# Configuration constants are grouped together
const MOVEMENT = {
	MIN_THRUST = 500,
	MAX_THRUST = 3000,
	DEFAULT_THRUST = 1000,
	DEFAULT_TORQUE = 100
}

const LANDING = {
	DEFAULT_MAX_ANGLE = 20.0,
	DEFAULT_CRITICAL_ANGLE = 45.0,
	DEFAULT_STABLE_TIME = 1.0,
	DEFAULT_MAX_VELOCITY = 5.0
}

const PHYSICS = {
	DEFAULT_TIPPING_MULTIPLIER = 0.5,
	DEFAULT_BASE_STABILITY = 100.0
}

# Input parameters
@export_range(MOVEMENT.MIN_THRUST, MOVEMENT.MAX_THRUST) var thrust: int = MOVEMENT.DEFAULT_THRUST
@export var torque: int = MOVEMENT.DEFAULT_TORQUE

# Landing parameters
@export_range(0, 90) var max_landing_angle: float = LANDING.DEFAULT_MAX_ANGLE
@export_range(0, 90) var critical_tipping_angle: float = LANDING.DEFAULT_CRITICAL_ANGLE
@export var required_stable_time: float = LANDING.DEFAULT_STABLE_TIME
@export var max_landing_velocity: float = LANDING.DEFAULT_MAX_VELOCITY

# Physics parameters
@export var tipping_torque_multiplier: float = PHYSICS.DEFAULT_TIPPING_MULTIPLIER
@export var base_stability: float = PHYSICS.DEFAULT_BASE_STABILITY

# State variables
var current_stable_time: float = 0.0
var is_on_landing_pad: bool = false:
	set(value):
		if is_on_landing_pad != value:
			is_on_landing_pad = value
			landing_state_changed.emit(value)
var is_transitioning: bool = false
var has_exploded: bool = false
var is_thrusting: bool = false:
	set(value):
		if is_thrusting != value:
			is_thrusting = value
			particles.booster.emitting = value
			sounds.bubbles.playing = value 

# Node references - grouped by functionality
@onready var particles = {
	booster = $BoosterBubblesCenter,
	right_booster = $BoosterBubblesRight,
	left_booster = $BoosterBubblesLeft,
	explosion = $ExplosionBubbles,
	success = $SuccessBubbles,
}

@onready var sounds = {
	explosion = $ExplosionAudio,
	success = $SuccessAudio,
	bubbles = $BubblesAudio,
}

# Core lifecycle methods
func _ready() -> void:
	# Connect internal signal handlers
	crash_started.connect(_on_crash_started)
	crash_completed.connect(_on_crash_completed)
	level_completed.connect(_on_level_completed)
	landing_state_changed.connect(_on_landing_state_changed)
	
	# Ensure audio starts in stopped state
	sounds.bubbles.playing = false

func _physics_process(delta: float) -> void:
	if is_transitioning:
		return
		
	process_movement(delta)
	process_stability(delta)
	process_landing(delta)

# Signal handlers
func _on_body_entered(body: Node) -> void:
	if not has_exploded and not is_transitioning and "Hazard" in body.get_groups():
		start_crash_sequence()

func _on_crash_started() -> void:
	has_exploded = true
	is_thrusting = false
	is_transitioning = true
	set_process(false)
	particles.explosion.emitting = true
	sounds.explosion.playing = true
	
func _on_crash_completed() -> void:
	get_tree().reload_current_scene()

func _on_level_completed(next_level: String) -> void:
	is_transitioning = true
	set_process(false)
	particles.success.emitting = true
	sounds.success.playing = true
	
	var tween = create_tween()
	tween.tween_interval(2)
	tween.tween_callback(func(): get_tree().change_scene_to_file(next_level))

func _on_landing_state_changed(on_pad: bool) -> void:
	if not on_pad:
		current_stable_time = 0.0

# State change methods
func start_crash_sequence() -> void:
	if has_exploded:
		return
	
	crash_started.emit()
	var tween = create_tween()
	tween.tween_interval(2.5)
	tween.tween_callback(func(): crash_completed.emit())

# Movement handling
func process_movement(delta: float) -> void:
	handle_thrust(delta)
	handle_rotation(delta)

func handle_thrust(delta: float) -> void:
	var new_thrust_state = Input.is_action_pressed("boost")
	if new_thrust_state != is_thrusting:
		is_thrusting = new_thrust_state
		# Update effects when state changes
		particles.booster.emitting = is_thrusting
		sounds.bubbles.playing = is_thrusting
	
	if is_thrusting:
		apply_central_force(basis.y * thrust * delta)

func handle_rotation(delta: float) -> void:
	var rotation_direction = Input.get_axis("rotate_right", "rotate_left")
	if rotation_direction != 0:
		var torque_amount = torque * delta * rotation_direction
		apply_torque(Vector3(0, 0, torque_amount))
	update_rotation_effects(-rotation_direction)

# Stability handling
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
	var tilt_direction := global_transform.basis.y.cross(Vector3.UP)
	
	var tilt_factor = (tilt_angle - max_landing_angle) / \
					 (critical_tipping_angle - max_landing_angle)
	
	var base_factor = 1.0 - (base_stability / (tilt_angle + base_stability))
	return tilt_direction.dot(right_vector) * tipping_torque_multiplier * tilt_factor * base_factor * delta

func get_tilt_angle() -> float:
	var up_direction := global_transform.basis.y
	return rad_to_deg(acos(up_direction.dot(Vector3.UP)))

func is_upright() -> bool:
	return get_tilt_angle() <= max_landing_angle

func is_critically_tipped() -> bool:
	return get_tilt_angle() >= critical_tipping_angle

func is_landing_stable() -> bool:
	return is_upright() and linear_velocity.length() <= max_landing_velocity

# Landing handling
func process_landing(delta: float) -> void:
	update_landing_pad_state()
	
	if not is_on_landing_pad:
		return
		
	if not has_exploded and is_critically_tipped():
		start_crash_sequence()
	elif is_landing_stable():
		current_stable_time += delta
		if current_stable_time >= required_stable_time:
			handle_successful_landing()

func update_landing_pad_state() -> void:
	var landing_pad = get_landing_pad()
	self.is_on_landing_pad = landing_pad != null  # Uses setter

func get_landing_pad() -> Node:
	for body in get_colliding_bodies():
		if "Goal" in body.get_groups():
			return body
	return null

func handle_successful_landing() -> void:
	var landing_pad = get_landing_pad()
	if landing_pad and landing_pad.has_method("get_next_level_path"):
		level_completed.emit(landing_pad.get_next_level_path())

# Visual effects
func update_thrust_effects(is_thrusting: bool) -> void:
	particles.booster.emitting = is_thrusting
	sounds.bubbles.playing = is_thrusting

func update_rotation_effects(rotation_direction: float) -> void:
	particles.left_booster.emitting = rotation_direction < 0
	particles.right_booster.emitting = rotation_direction > 0
