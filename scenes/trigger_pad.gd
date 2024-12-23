extends Area3D
class_name TriggerPad

signal pad_activated
@onready var animation_player: AnimationPlayer = $AnimationPlayer

# The path to the door node this pad controls
@export var controlled_door_path: NodePath

var is_activated: bool = false
var controlled_door: Node3D

func _ready() -> void:
	if not controlled_door_path.is_empty():
		controlled_door = get_node(controlled_door_path)

func activate_pad() -> void:
	if is_activated:
		return
	
	is_activated = true
	
	animation_player.play("button_press")
	
	if controlled_door and controlled_door.has_method("open"):
		controlled_door.open()
	
	pad_activated.emit()


# This function is automatically called when a physics body enters our trigger areaitor
func _on_body_entered(body: Node3D) -> void:
	# We only want to respond to the player, and only if we haven't been activated yet
	if body.is_in_group("player") and not is_activated:
		activate_pad()
