extends RigidBody3D
class_name RocketController

signal crashed
signal crash_ended
signal level_finished(next_level_path: String)
signal landing_state_changed(is_on_pad: bool)

enum State { FLYING, LANDING, CRASHED, TRANSITIONING }

const UP_VECTOR := Vector3.UP

@export_group("Movement")
@export_range(100, 1000) var thrust: int = 25
@export var thrust_dampening: float = 0.5
@export var max_velocity: float = 50.0

@export var torque: int = 100

@export_group("Landing")
@export_range(0, 90) var max_landing_angle: float = 60.0
@export_range(0, 90) var critical_tipping_angle: float = 90.0
@export var required_stable_time: float = 0.5
@export var max_landing_velocity: float = 50.0

@export_group("Physics")
@export var tipping_torque_multiplier: float = 0.3
@export var base_stability: float = 150.0

@export_group("Fuel")
@export var max_fuel: float = 100
@export var fuel_decrease: float = 10
@export var boost_fuel_cost: float = 30.0
@export var boost_thrust: float = 75.0
@export var boost_duration: float = 0.2

var thrust_active: bool = false
var is_thrusting: bool = false:
	set(value):
		if is_thrusting != value:
			is_thrusting = value

var current_fuel: float = max_fuel
var boosting: bool = false
var boost_timer: float = 0.0

var current_state: State = State.FLYING
var current_stable_time: float = 0.0
var is_on_landing_pad: bool = false:
	set(value):
		if is_on_landing_pad != value:
			is_on_landing_pad = value
			landing_state_changed.emit(value)

var time_since_critical_tilt: float = 0.0
var last_tilt_check_time: float = 0.0
var tilt_angle: float = 0.0

@onready var movement = $Movement
@onready var fuel_controller = $Fuel
@onready var stability = $Stability
@onready var landing = $Landing
@onready var effects = $Effects


func _ready():
	await get_tree().process_frame  # Ensure children are ready
	connect_signals()
	fuel_controller.setup_fuel(max_fuel, current_fuel)
	effects.get_node("BubblesAudio").playing = false
	stability.tilt_changed.connect(_on_tilt_changed)

func _process(delta: float):
	fuel_controller.process(delta)  # Fuel usage checks here

func _physics_process(delta: float):
	if current_state in [State.TRANSITIONING, State.CRASHED]:
		return

	movement.process(delta)
	stability.process(delta)
	landing.process(delta)

func connect_signals():
	# Custom rocket signals
	crashed.connect(_on_crashed)
	crash_ended.connect(_on_crash_ended)
	level_finished.connect(_on_level_finished)
	landing_state_changed.connect(_on_landing_state_changed)
	
func _on_body_entered(body: Node3D):
	# Don't process collisions if we're already crashed or transitioning
	if current_state in [State.CRASHED, State.TRANSITIONING]:
		return
		
	# Ignore collisions with landing pads - they're handled by the landing controller
	if body.is_in_group("Goal"):
		return
		
	# Check if impact velocity is dangerous
	var impact_velocity = linear_velocity.length()
	if impact_velocity > max_landing_velocity:
		start_crash_sequence()
		return
		
	# Check if impact angle is dangerous
	if tilt_angle > critical_tipping_angle:
		start_crash_sequence()
		return

func _on_boost_requested():
	if current_fuel >= boost_fuel_cost:
		movement.activate_boost()

func _on_crashed():
	current_state = State.CRASHED
	set_process(false)
	effects.play_explosion()

func _on_crash_ended():
	get_tree().reload_current_scene()

func _on_tilt_changed(tilt: float):
	tilt_angle = tilt

func _on_level_finished(next_level_path: String):
	current_state = State.TRANSITIONING
	set_process(false)
	effects.play_success_particles()
	effects.play_success_sound()
	var tween = create_tween()
	tween.tween_interval(2)
	tween.tween_callback(func(): get_tree().change_scene_to_file(next_level_path))

func _on_landing_state_changed(on_pad: bool):
	if not on_pad:
		current_stable_time = 0.0

func start_crash_sequence():
	if current_state == State.CRASHED:
		return
	crashed.emit()
	var tween = create_tween()
	tween.tween_interval(2.5)
	tween.tween_callback(func(): crash_ended.emit())

func activate_boost():
	current_fuel -= boost_fuel_cost
	current_fuel = clamp(current_fuel, 0.0, max_fuel)
	boosting = true
	boost_timer = boost_duration
