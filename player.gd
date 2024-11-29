extends RigidBody3D

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
var is_on_landing_pad: bool = false
var is_transitioning: bool = false

# Node references - grouped by functionality
#@onready var audio = {
	#explosion = $ExplosionAudio,
	#success = $SuccessAudio,
	#rocket = $RocketAudio
#}
#
@onready var particles = {
	booster = $BoosterBubblesCenter,
	right_booster = $BoosterBubblesRight,
	left_booster = $BoosterBubblesLeft,
	#explosion = $ExplosionParticles,
	#success = $SuccessParticles
}

# Core lifecycle methods
func _physics_process(delta: float) -> void:
	if is_transitioning:
		return
		
	MovementSystem.process_movement(self, delta)
	StabilitySystem.process_stability(self, delta)
	LandingSystem.process_landing(self, delta)

# Signal handlers
func _on_body_entered(body: Node) -> void:
	if not is_transitioning and "Hazard" in body.get_groups():
		TransitionSystem.start_crash_sequence(self)

# Systems are organized into separate classes for clarity
class MovementSystem:
	static func process_movement(rocket: RigidBody3D, delta: float) -> void:
		handle_thrust(rocket, delta)
		handle_rotation(rocket, delta)
	
	static func handle_thrust(rocket: RigidBody3D, delta: float) -> void:
		var is_thrusting = Input.is_action_pressed("boost")
		if is_thrusting:
			rocket.apply_central_force(rocket.basis.y * rocket.thrust * delta)
		EffectsSystem.update_thrust_effects(rocket, is_thrusting)
	
	static func handle_rotation(rocket: RigidBody3D, delta: float) -> void:
		var rotation_direction = Input.get_axis("rotate_right", "rotate_left")
		if rotation_direction != 0:
			var torque_amount = rocket.torque * delta * rotation_direction
			rocket.apply_torque(Vector3(0, 0, torque_amount))
		EffectsSystem.update_rotation_effects(rocket, -rotation_direction)

class StabilitySystem:
	static func process_stability(rocket: RigidBody3D, delta: float) -> void:
		if rocket.is_on_landing_pad:
			apply_tipping_forces(rocket, delta)
	
	static func apply_tipping_forces(rocket: RigidBody3D, delta: float) -> void:
		var tilt_angle = get_tilt_angle(rocket)
		if tilt_angle > rocket.max_landing_angle and tilt_angle < rocket.critical_tipping_angle:
			var tipping_torque = calculate_tipping_torque(rocket, tilt_angle, delta)
			rocket.apply_torque(Vector3(0, 0, tipping_torque))
	
	static func calculate_tipping_torque(rocket: RigidBody3D, tilt_angle: float, delta: float) -> float:
		var right_vector := rocket.global_transform.basis.x
		var tilt_direction := rocket.global_transform.basis.y.cross(Vector3.UP)
		
		var tilt_factor = (tilt_angle - rocket.max_landing_angle) / \
						 (rocket.critical_tipping_angle - rocket.max_landing_angle)
		
		var base_factor = 1.0 - (rocket.base_stability / (tilt_angle + rocket.base_stability))
		return tilt_direction.dot(right_vector) * rocket.tipping_torque_multiplier * tilt_factor * base_factor * delta
	
	static func get_tilt_angle(rocket: RigidBody3D) -> float:
		var up_direction := rocket.global_transform.basis.y
		return rad_to_deg(acos(up_direction.dot(Vector3.UP)))
	
	static func is_upright(rocket: RigidBody3D) -> bool:
		return get_tilt_angle(rocket) <= rocket.max_landing_angle
	
	static func is_critically_tipped(rocket: RigidBody3D) -> bool:
		return get_tilt_angle(rocket) >= rocket.critical_tipping_angle
	
	static func is_landing_stable(rocket: RigidBody3D) -> bool:
		return is_upright(rocket) and rocket.linear_velocity.length() <= rocket.max_landing_velocity

class LandingSystem:
	static func process_landing(rocket: RigidBody3D, delta: float) -> void:
		var landing_pad = get_landing_pad(rocket)
		rocket.is_on_landing_pad = landing_pad != null
		
		if not rocket.is_on_landing_pad:
			rocket.current_stable_time = 0.0
			return
			
		if StabilitySystem.is_critically_tipped(rocket):
			TransitionSystem.start_crash_sequence(rocket)
		elif StabilitySystem.is_landing_stable(rocket):
			rocket.current_stable_time += delta
			if rocket.current_stable_time >= rocket.required_stable_time:
				handle_successful_landing(rocket, landing_pad)
	
	static func get_landing_pad(rocket: RigidBody3D) -> Node:
		for body in rocket.get_colliding_bodies():
			if "Goal" in body.get_groups():
				return body
		return null
	
	static func handle_successful_landing(rocket: RigidBody3D, landing_pad: Node) -> void:
		if landing_pad.has_method("get_next_level_path"):
			TransitionSystem.complete_level(rocket, landing_pad.get_next_level_path())

class TransitionSystem:
	static func start_crash_sequence(rocket: RigidBody3D) -> void:
		rocket.is_transitioning = true
		rocket.set_process(false)
		
		EffectsSystem.play_crash_effects(rocket)
		
		var tween = rocket.create_tween()
		tween.tween_interval(2.5)
		tween.tween_callback(rocket.get_tree().reload_current_scene)
	
	static func complete_level(rocket: RigidBody3D, next_level_file: String) -> void:
		rocket.is_transitioning = true
		rocket.set_process(false)
		
		EffectsSystem.play_success_effects(rocket)
		
		var tween = rocket.create_tween()
		tween.tween_interval(1)
		tween.tween_callback(
			rocket.get_tree().change_scene_to_file.bind(next_level_file)
		)

class EffectsSystem:
	static func update_thrust_effects(rocket: RigidBody3D, is_thrusting: bool) -> void:
		#if is_thrusting:
			#if not rocket.audio.rocket.playing:
				#rocket.audio.rocket.play()
		#else:
			#rocket.audio.rocket.stop()
		#
		rocket.particles.booster.emitting = is_thrusting
	
	static func update_rotation_effects(rocket: RigidBody3D, rotation_direction: float) -> void:
		rocket.particles.left_booster.emitting = rotation_direction < 0
		rocket.particles.right_booster.emitting = rotation_direction > 0

	static func play_crash_effects(rocket: RigidBody3D) -> void:
		#rocket.particles.explosion.emitting = true
		#rocket.audio.explosion.play()
		pass
	
	static func play_success_effects(rocket: RigidBody3D) -> void:
		#rocket.particles.success.emitting = true
		#rocket.audio.success.play()
		pass
