extends Control

## The scene to load when the Start Game button is pressed.
## 
## This path should point to your main game scene. The scene will be loaded
## using threaded loading when the menu appears to improve performance.
## 
## [b]Note:[/b] Make sure the target scene exists and is a valid [code].tscn[/code] file.
## If no scene is specified, an error will be logged to the output panel.
@export_file("*.tscn") var game_scene_path: String = "res://scenes/game.tscn"

# Store the loading status
var _loading_started: bool = false
var _loading_progress: Array[float] = []

func _ready() -> void:
	# Connect the button's pressed signal
	$MarginContainer/VBoxContainer/StartGameButton.pressed.connect(_on_start_game_button_pressed)
	
	# Start prefetching the game scene
	_start_scene_prefetch()

## Begins asynchronous loading of the target scene.
## This improves performance by loading the scene in the background while the menu is visible.
func _start_scene_prefetch() -> void:
	if game_scene_path.is_empty():
		push_error("No game scene path specified in MainMenu")
		return
	
	# Check if the scene is already cached
	if ResourceLoader.has_cached(game_scene_path):
		return
		
	# Begin background loading
	var error = ResourceLoader.load_threaded_request(game_scene_path)
	if error != OK:
		push_error("Failed to start loading scene: " + game_scene_path)
		return
		
	_loading_started = true

## Called every frame while the menu is visible.
## Monitors the loading progress of the prefetched scene.
func _process(_delta: float) -> void:
	if not _loading_started:
		return
		
	# Check the loading status
	var status = ResourceLoader.load_threaded_get_status(game_scene_path, _loading_progress)
	
	match status:
		ResourceLoader.THREAD_LOAD_LOADED:
			# Loading finished successfully
			_loading_started = false
		ResourceLoader.THREAD_LOAD_FAILED:
			# Loading failed
			push_error("Failed to load scene: " + game_scene_path)
			_loading_started = false
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			# Invalid resource
			push_error("Invalid scene resource: " + game_scene_path)
			_loading_started = false
		ResourceLoader.THREAD_LOAD_IN_PROGRESS:
			# Still loading - you could update a progress bar here
			pass

## Handles the start game button press event.
## Changes to the prefetched scene if it's ready, otherwise waits for loading to complete.
func _on_start_game_button_pressed() -> void:
	if game_scene_path.is_empty():
		push_error("No game scene path specified in MainMenu")
		return
	
	if _loading_started:
		# Scene is still loading, wait for it to complete
		await get_tree().create_timer(0.1).timeout
		_on_start_game_button_pressed()  # Try again after a short delay
		return
		
	# Get the loaded scene resource
	var scene: PackedScene
	if ResourceLoader.has_cached(game_scene_path):
		scene = ResourceLoader.load_threaded_get(game_scene_path) as PackedScene
	else:
		# Fallback to synchronous loading if prefetch failed
		scene = load(game_scene_path) as PackedScene
	
	if scene == null:
		push_error("Failed to get scene: " + game_scene_path)
		return
		
	# Change to the loaded scene
	var error = get_tree().change_scene_to_packed(scene)
	if error != OK:
		push_error("Failed to change to scene: " + game_scene_path)
