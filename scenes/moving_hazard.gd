extends AnimatableBody3D

## Target position relative to the object's initial position
@export var desired_position: Vector3 = Vector3.ZERO

## Target rotation in degrees relative to the initial rotation
@export var desired_rotation: Vector3 = Vector3.ZERO

## Time in seconds for one complete animation cycle
@export var desired_duration: float = 1.0

var _initial_transform: Transform3D

func _ready() -> void:
	_initial_transform = transform
	
	# Create target transform from position and rotation
	var target_transform = Transform3D()
	target_transform = target_transform.translated(desired_position)
	target_transform = target_transform.rotated(Vector3.RIGHT, deg_to_rad(desired_rotation.x))
	target_transform = target_transform.rotated(Vector3.UP, deg_to_rad(desired_rotation.y))
	target_transform = target_transform.rotated(Vector3.FORWARD, deg_to_rad(desired_rotation.z))
	
	var tween = create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	
	# Forward phase: Tween to combined transform
	tween.tween_property(
		self,
		"transform",
		_initial_transform * target_transform,
		desired_duration
	)
	
	# Return phase: Tween back to initial transform
	tween.chain().tween_property(
		self,
		"transform",
		_initial_transform,
		desired_duration
	)
