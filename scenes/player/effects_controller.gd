extends Node
class_name EffectsController

@onready var parent: RocketController = get_parent() as RocketController

# Main particle systems
@onready var explosion_particles: GPUParticles3D = $ExplosionBubbles
@onready var success_particles: GPUParticles3D = $SuccessBubbles
@onready var main_booster_particles: GPUParticles3D = $BoosterBubblesCenter
@onready var left_booster_particles: GPUParticles3D = $BoosterBubblesLeft
@onready var right_booster_particles: GPUParticles3D = $BoosterBubblesRight

# Audio systems
@onready var explosion_sound: AudioStreamPlayer3D = $ExplosionAudio
@onready var success_sound: AudioStreamPlayer3D = $SuccessAudio
@onready var bubbles_sound: AudioStreamPlayer3D = $BubblesAudio

func _ready():
	await get_tree().process_frame
	connect_signals()

func connect_signals():
	if parent:
		parent.crashed.connect(_on_crashed)
		parent.crash_ended.connect(_on_crash_ended)
		parent.landing_state_changed.connect(_on_landing_state_changed)
		if parent.movement:
			parent.movement.boost_activated.connect(_on_boost_activated)
			parent.movement.boost_deactivated.connect(_on_boost_deactivated)
		if parent.fuel_controller:
			parent.fuel_controller.fuel_depleted.connect(_on_fuel_depleted)

# Crash effects
func _on_crashed():
	play_explosion()

func _on_crash_ended():
	stop_explosion_effects()

# Success effects
func _on_level_finished():
	play_success_particles()
	play_success_sound()

func _on_landing_state_changed(on_pad: bool):
	if not on_pad:
		stop_success_effects()

# Movement effects
func _on_fuel_depleted():
	update_thrust_effects(false)

func _on_boost_activated():
	play_boost_effects()

func _on_boost_deactivated():
	stop_boost_effects()

func update_thrust_effects(is_thrusting: bool):
	main_booster_particles.emitting = is_thrusting
	bubbles_sound.playing = is_thrusting

func update_rotation_effects(rotation_direction: float):
	left_booster_particles.emitting = rotation_direction < 0
	right_booster_particles.emitting = rotation_direction > 0

# Effect control methods
func play_explosion():
	explosion_particles.emitting = true
	explosion_sound.play()

func stop_explosion_effects():
	explosion_particles.emitting = false

func play_success_particles():
	success_particles.emitting = true

func play_success_sound():
	success_sound.play()

func stop_success_effects():
	success_particles.emitting = false

func play_boost_effects():
	main_booster_particles.emitting = true
	bubbles_sound.play()

func stop_boost_effects():
	main_booster_particles.emitting = false
	bubbles_sound.stop()
