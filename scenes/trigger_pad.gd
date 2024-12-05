extends StaticBody3D
class_name TriggerPad

signal pad_activated

# The path to the door node this pad controls
@export var controlled_door_path: NodePath

# Optional visual feedback
@export var activation_particles: GPUParticles3D
@export var activation_sound: AudioStreamPlayer3D

# We'll track activation state to prevent multiple triggers
var is_activated: bool = false
var controlled_door: Node3D

func _ready() -> void:
	# Connect to our door if a valid path is provided
	if not controlled_door_path.is_empty():
		controlled_door = get_node(controlled_door_path)
	
	# Add to the "Goal" group so the rocket can detect it using existing logic
	add_to_group("Goal")

# This is required to maintain compatibility with your rocket's landing system
func get_next_level_path() -> String:
	return ""  # Empty string indicates no level transition

func activate_pad() -> void:
	# Prevent multiple activations
	if is_activated:
		return
		
	is_activated = true
	
	# Trigger visual and audio feedback if configured
	if activation_particles:
		activation_particles.emitting = true
	if activation_sound:
		activation_sound.play()
	
	# Open the connected door
	if controlled_door and controlled_door.has_method("open"):
		controlled_door.open()
	
	# Emit signal for any other game systems that might need it
	pad_activated.emit()
