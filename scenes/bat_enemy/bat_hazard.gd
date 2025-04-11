extends Area3D

signal player_hit

func _ready():
	# Nothing needed here - the signal is already connected in the scene
	pass

func _on_body_entered(body):
	# Check if the colliding body is a player
	if body.is_in_group("player"):
		player_hit.emit()
		print("Bat hit player!")
		
		# Directly call the crash sequence on the rocket
		if body.has_method("start_crash_sequence"):
			body.start_crash_sequence()
	# If it's not the player directly, check if it's a component of the player
	elif body.get_parent() and body.get_parent().has_method("start_crash_sequence"):
		player_hit.emit()
		print("Bat hit player component!")
		body.get_parent().start_crash_sequence()
