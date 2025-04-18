extends PathFollow3D

@export var speed: float = 5.0
@export var jitter_intensity: float = 0.5
@export var should_loop: bool = true

var rng := RandomNumberGenerator.new()
var direction: int = 1
var is_active: bool = false
var rotates: bool = true

func _ready():
	# Initialize the path follower
	progress_ratio = 0.0
	rotates = true
	is_active = true

func _process(delta):
	if not is_active:
		return
		
	# Move along the path with safety checks
	var new_progress = progress + (speed * delta * direction)
	
	# Check boundaries and update direction
	if direction > 0 and progress_ratio >= 1.0:
		direction = -1
		new_progress = progress # Stay at current position
	elif direction < 0 and progress_ratio <= 0.0:
		direction = 1
		new_progress = 0.0
	
	progress = new_progress
	
	# Add subtle jitter
	if jitter_intensity > 0:
		position += Vector3(
			rng.randf_range(-jitter_intensity, jitter_intensity),
			rng.randf_range(-jitter_intensity, jitter_intensity),
			rng.randf_range(-jitter_intensity, jitter_intensity)
		) * delta
