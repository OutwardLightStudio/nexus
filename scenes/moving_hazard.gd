extends AnimatableBody3D

@export_group("Desired Transform")
## Target position relative to the object's initial position
@export var desired_position: Vector3 = Vector3.ZERO
## Target rotation in degrees relative to the initial rotation
@export var desired_rotation: Vector3 = Vector3.ZERO
## Target scale relative to the initial scale (1.0 = no change)
@export var desired_scale: Vector3 = Vector3.ONE
## Time in seconds for one complete animation cycle
@export var transform_duration: float = 1.0

var _initial_transform: Transform3D

func _ready() -> void:
	_initial_transform = transform
	
	# Create target transform incorporating position, rotation, and scale
	var target_transform = Transform3D()
	target_transform = target_transform.translated(desired_position)
	target_transform = target_transform.rotated(Vector3.RIGHT, deg_to_rad(desired_rotation.x))
	target_transform = target_transform.rotated(Vector3.UP, deg_to_rad(desired_rotation.y))
	target_transform = target_transform.rotated(Vector3.FORWARD, deg_to_rad(desired_rotation.z))
	target_transform.basis = target_transform.basis.scaled(desired_scale)
	
	
	var tween = create_tween().set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	
	# Forward phase: Tween to the complete target transform
	tween.tween_property(
		self,
		"transform",
		_initial_transform * target_transform,
		transform_duration
	)
	
	# Return phase: Tween back to initial transform
	tween.chain().tween_property(
		self,
		"transform",
		_initial_transform,
		transform_duration
	)
