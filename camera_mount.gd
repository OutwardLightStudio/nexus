extends Node3D

@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D

@export var smoothing_speed: float = 2.0
@export var initial_distance: float = 5.0

func _ready() -> void:
	set_as_top_level(true)
	
	# Set up initial camera position with correct offset
	var initial_pos = get_parent().global_position
	initial_pos.z += initial_distance
	global_position = initial_pos
	
	# Configure spring arm
	spring_arm.spring_length = initial_distance
	spring_arm.margin = 0.5
	spring_arm.collision_mask = 1
	
	camera.global_rotation = Vector3.ZERO
	
	# Ensure camera starts at the correct distance
	spring_arm.position = Vector3.ZERO
	spring_arm.rotation = Vector3.ZERO

func _process(delta: float) -> void:
	var target = get_parent().global_position
	
	# Maintain correct Z-offset while following
	target.z = get_parent().global_position.z + initial_distance
	
	# Smooth position following
	global_position = global_position.lerp(target, delta * smoothing_speed)
	
	# Maintain orientation
	camera.global_rotation = Vector3.ZERO
	spring_arm.global_rotation = Vector3.ZERO
