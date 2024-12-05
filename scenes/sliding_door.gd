extends StaticBody3D
class_name SlidingDoor

# Door movement configuration
@export_group("Movement")
@export var open_distance: float = 3.0
@export var open_duration: float = 1.0
@export var open_direction: Vector3 = Vector3.UP
@export var movement_curve: Curve

# Optional effects
@export_group("Effects")
@export var movement_sound: AudioStreamPlayer3D
@export var door_particles: GPUParticles3D

var is_open: bool = false
var initial_position: Vector3

func _ready() -> void:
	# Store our starting position for animations
	initial_position = position
	
	# Create a default curve if none is provided
	if not movement_curve:
		movement_curve = Curve.new()
		movement_curve.add_point(Vector2(0, 0), 0, 2)
		movement_curve.add_point(Vector2(1, 1), 0.5, 0)

func open() -> void:
	if is_open:
		return
	
	is_open = true
	
	# Create smooth door movement
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	
	# Animate the door's position
	tween.tween_property(
		self,
		"position",
		initial_position + (open_direction.normalized() * open_distance),
		open_duration
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	
	# Play effects if configured
	if movement_sound:
		movement_sound.play()
	if door_particles:
		door_particles.emitting = true
