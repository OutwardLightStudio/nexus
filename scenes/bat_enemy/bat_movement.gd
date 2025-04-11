extends PathFollow3D

@export var speed: float = 5.0
@export var jitter_intensity: float = 0.5
@export var min_pause_time: float = 3.0
@export var max_pause_time: float = 7.0

var rng := RandomNumberGenerator.new()
var direction: int = 1
var previous_direction: int = 1
var rotates: bool = true
var is_active: bool = true
var is_paused: bool = false
var pause_timer: float = 0.0
var current_pause_duration: float = 0.0
var bat_model: Node3D

func _ready():
	# Initialize the path follower
	progress_ratio = 0.0
	rotates = true
	rng.randomize()
	
	# Get reference to bat model for rotation
	# The bat model should be in the child node structure
	if get_child_count() > 0:
		# Try to find the bat model in children
		for child in get_children():
			if child.get_child_count() > 0 and child.get_child(0).name == "BatModel":
				bat_model = child.get_child(0)
				break
			if child.name == "BatModel" or "bat" in child.name.to_lower():
				bat_model = child
				break

func _process(delta):
	if not is_active:
		return
		
	# Handle paused state
	if is_paused:
		pause_timer += delta
		if pause_timer >= current_pause_duration:
			# Resume movement after pause
			is_paused = false
		return
	
	# Store previous direction to detect changes
	previous_direction = direction
	
	# Move along the path with safety checks
	var new_progress = progress + (speed * delta * direction)
	
	# Check boundaries and reverse direction at endpoints
	if direction > 0 and progress_ratio >= 0.99:
		start_pause()
		direction = -1
	elif direction < 0 and progress_ratio <= 0.01:
		start_pause()
		direction = 1
	
	# Check if direction changed
	if previous_direction != direction and bat_model != null:
		# Rotate the bat model 180 degrees around the Y axis
		bat_model.rotation_degrees.y += 180
	
	# Apply movement when not paused
	if !is_paused:
		progress = new_progress
	
	# Add subtle jitter for more natural movement
	if jitter_intensity > 0 and !is_paused:
		position += Vector3(
			rng.randf_range(-jitter_intensity, jitter_intensity),
			rng.randf_range(-jitter_intensity, jitter_intensity),
			rng.randf_range(-jitter_intensity, jitter_intensity)
		) * delta

# Start a random pause
func start_pause():
	is_paused = true
	pause_timer = 0.0
	current_pause_duration = rng.randf_range(min_pause_time, max_pause_time)
