extends CSGBox3D

@export_file("*.tscn") var file_path


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	pass

func get_next_level_path() -> String:
	## Returns the file path to the next level scene
	## This path is set in the editor using the file_path export variable
	return file_path
