extends StaticBody3D

@onready var area3d: Area3D = $Area3D  # Reference to the Area3D child node
@export var refuel_rate: float = 10.0  # Fuel added per second to the rocket

var rocket: RocketController = null  # Reference to the rocket on the pad

func _ready():
	# Connect Area3D signals to handle body enter and exit events
	area3d.body_entered.connect(_on_body_entered)
	area3d.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D):
	# Check if the body entering the pad is the rocket
	if body is RocketController:
		rocket = body  # Keep a reference to the rocket
		print("Rocket entered the refueling pad")

func _on_body_exited(body: Node3D):
	# Check if the body exiting the pad is the rocket
	if body is RocketController:
		rocket = null  # Clear the reference when the rocket leaves
		print("Rocket exited the refueling pad")

func _process(delta: float):
	# If a rocket is on the pad and its fuel is not full, refuel it
	if rocket and rocket.current_fuel < rocket.max_fuel:
		# Increment the rocket's fuel
		rocket.current_fuel += refuel_rate * delta
		rocket.current_fuel = clamp(rocket.current_fuel, 0, rocket.max_fuel)
		
		# Update the fuel gauge (assuming fuel_controller handles the slider)
		if rocket.fuel_controller:
			rocket.fuel_controller.update_fuel_display(rocket.current_fuel)