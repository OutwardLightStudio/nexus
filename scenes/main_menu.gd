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

# Get references to UI elements
@onready var loading_container = $MarginContainer/VBoxContainer/LoadingContainer
@onready var loading_progress = $MarginContainer/VBoxContainer/LoadingContainer/LoadingProgress
@onready var start_button = $MarginContainer/VBoxContainer/StartGameButton

func _ready() -> void:
	start_button.pressed.connect(_on_start_game_button_pressed)
	_start_scene_prefetch()
	loading_progress.min_value = 0
	loading_progress.max_value = 100
	loading_progress.value = 0

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
	loading_container.show()
	start_button.disabled = true

## Called every frame while the menu is visible.
## Monitors the loading progress of the prefetched scene.
func _process(_delta: float) -> void:
	if not _loading_started:
		return
		
	# Check the loading status
	var status = ResourceLoader.load_threaded_get_status(game_scene_path, _loading_progress)
	
	if _loading_progress.size() > 0:
		loading_progress.value = _loading_progress[0] * 100
	
	match status:
		ResourceLoader.THREAD_LOAD_LOADED:
			# Loading finished successfully
			_loading_started = false
			loading_container.hide()
			start_button.disabled = false
		ResourceLoader.THREAD_LOAD_FAILED:
			# Loading failed
			push_error("Failed to load scene: " + game_scene_path)
			_loading_started = false
			loading_container.hide()
			start_button.disabled = false
		ResourceLoader.THREAD_LOAD_INVALID_RESOURCE:
			# Invalid resource
			push_error("Invalid scene resource: " + game_scene_path)
			_loading_started = false
			loading_container.hide()
			start_button.disabled = false
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
		return
		
	# Get the loaded scene resource
	var scene: PackedScene
	if ResourceLoader.has_cached(game_scene_path):
		scene = ResourceLoader.load_threaded_get(game_scene_path) as PackedScene
	else:
		# Fallback to synchronous loading if prefetch failed
		loading_container.show()
		scene = load(game_scene_path) as PackedScene
	
	if scene == null:
		push_error("Failed to get scene: " + game_scene_path)
		loading_container.hide()
		return
		
	# Change to the loaded scene
	var error = get_tree().change_scene_to_packed(scene)
	if error != OK:
		push_error("Failed to change to scene: " + game_scene_path)
		loading_container.hide()
