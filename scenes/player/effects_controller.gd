extends Node
class_name EffectsController

@onready var parent: RocketController = get_parent() as RocketController
@onready var explosion_particles: GPUParticles3D = $ExplosionBubbles
@onready var success_particles: GPUParticles3D = $SuccessBubbles
@onready var booster_particles: GPUParticles3D = parent.booster_particles

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
			parent.level_finished.connect(_on_level_finished)
			parent.landing_state_changed.connect(_on_landing_state_changed)

func _on_crashed():
	play_explosion()

func _on_crash_ended():
	stop_explosion_effects()

func _on_level_finished():
	play_success_particles()
	play_success_sound()

func _on_landing_state_changed(on_pad: bool):
	if not on_pad:
		stop_success_effects()

func _on_boost_requested():
	play_boost_effects()

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
	booster_particles.emitting = true
	bubbles_sound.play()
