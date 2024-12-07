extends RigidBody3D
class_name RocketController

signal crashed
signal crash_ended
signal level_finished(next_level_path: String)
signal landing_state_changed(is_on_pad: bool)

enum State {FLYING, LANDING, CRASHED, TRANSITIONING}

const UP_VECTOR := Vector3.UP

@export_group("Movement")
@export_range(500, 3000) var thrust: int = 1000
@export var torque: int = 100

@export_group("Landing")
@export_range(0, 90) var max_landing_angle: float = 60.0
@export_range(0, 90) var critical_tipping_angle: float = 90.0
@export var required_stable_time: float = 0.5
@export var max_landing_velocity: float = 50.0

@export_group("Physics")
@export var tipping_torque_multiplier: float = 0.3
@export var base_stability: float = 150.0

@export_group("Particles")
@export var explosion_particles: GPUParticles3D
@export var success_particles: GPUParticles3D
@export var booster_particles: GPUParticles3D

@export_group("Audio")
@export var explosion_sound: AudioStreamPlayer3D
@export var success_sound: AudioStreamPlayer3D
@export var bubbles_sound: AudioStreamPlayer3D

@export_group("Fuel")
@export var max_fuel: float = 100
@export var fuel_decrease: float = 10
@export var boost_fuel_cost: float = 30.0
@export var boost_thrust: float = 3000.0
@export var boost_duration: float = 0.2
var thrust_active: bool = false
var is_thrusting: bool = false:
	set(value):
		if is_thrusting != value:
			is_thrusting = value
			booster_particles.emitting = value
			bubbles_sound.playing = value
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

@onready var movement = $Movement
@onready var fuel = $Fuel
@onready var stability = $Stability
@onready var landing = $Landing
@onready var recovery = $Recovery
@onready var effects = $Effects
@onready var audio = $Audio

func _ready():
	_connect_signals()
	fuel.setup_fuel(max_fuel, current_fuel)
	audio.get_node("BubblesAudio").playing = false

func _process(delta: float):
	fuel.process(delta) # Fuel usage checks here

func _physics_process(delta: float):
	if current_state in [State.TRANSITIONING, State.CRASHED]:
		return

	movement.process(delta)
	stability.process(delta)
	landing.process(delta)

func _connect_signals():
	if not crashed.is_connected(_on_crashed):
		crashed.connect(_on_crashed)
	if not crash_ended.is_connected(_on_crash_ended):
		crash_ended.connect(_on_crash_ended)
	if not level_finished.is_connected(_on_level_finished):
		level_finished.connect(_on_level_finished)
	if not landing_state_changed.is_connected(_on_landing_state_changed):
		landing_state_changed.connect(_on_landing_state_changed)
		
	fuel.connect("fuel_depleted", Callable(self, "_on_fuel_depleted"))
	fuel.connect("boost_requested", Callable(self, "_on_boost_requested"))

func _on_fuel_depleted():
	thrust_active = false
	is_thrusting = false

func _on_boost_requested():
	if current_fuel >= boost_fuel_cost:
		activate_boost()

func _on_crashed():
	current_state = State.CRASHED
	movement.stop_thrust()
	set_process(false)
	explosion_particles.emitting = true
	explosion_sound.playing = true

func _on_crash_ended():
	get_tree().reload_current_scene()

func _on_level_finished(next_level_path: String):
	current_state = State.TRANSITIONING
	set_process(false)
	success_particles.emitting = true
	success_sound.playing = true
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
