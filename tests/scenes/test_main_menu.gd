extends GutTest

var MainMenu = load("res://scenes/main_menu.tscn")
var menu: Control
# Use the base level scene which should always exist
var test_scene_path = "res://levels/level.tscn"

func before_each():
	menu = MainMenu.instantiate()
	menu.game_scene_path = test_scene_path
	add_child_autoqfree(menu)
	await menu.ready

func test_initial_state():
	assert_false(menu._loading_started, "Loading should not be started initially")
	assert_false(menu.loading_container.visible, "Loading container should be hidden initially")
	assert_false(menu.start_button.disabled, "Start button should be enabled initially")
	assert_eq(menu.loading_progress.value, 0, "Loading progress should be 0 initially")

func test_scene_prefetch():
	# Trigger prefetch
	menu._start_scene_prefetch()
	
	assert_true(menu._loading_started, "Loading should be started")
	assert_true(menu.loading_container.visible, "Loading container should be visible")
	assert_true(menu.start_button.disabled, "Start button should be disabled during loading")
	
	# Wait for loading to complete
	await get_tree().process_frame
	
	# Check cleanup
	assert_false(menu._loading_started, "Loading should be finished")
	assert_false(menu.loading_container.visible, "Loading container should be hidden after load")
	assert_false(menu.start_button.disabled, "Start button should be enabled after load")

func test_invalid_scene_path():
	menu.game_scene_path = "res://non_existent.tscn"
	menu._start_scene_prefetch()
	
	await get_tree().process_frame
	
	assert_false(menu._loading_started, "Loading should be cancelled")
	assert_false(menu.loading_container.visible, "Loading container should be hidden")
	assert_false(menu.start_button.disabled, "Start button should be enabled")

func test_empty_scene_path():
	menu.game_scene_path = ""
	menu._start_scene_prefetch()
	
	assert_false(menu._loading_started, "Loading should not start with empty path")
	assert_false(menu.loading_container.visible, "Loading container should be hidden")
	assert_false(menu.start_button.disabled, "Start button should be enabled")

func test_loading_progress():
	menu._start_scene_prefetch()
	
	# Initial progress should be 0
	assert_eq(menu.loading_progress.value, 0, "Initial progress should be 0")
	
	# Wait for a frame to let progress update
	await get_tree().process_frame
	
	# Progress should be between 0 and 100
	var progress = menu.loading_progress.value
	assert_between(progress, 0, 100, "Progress should be between 0 and 100")

func test_cleanup_loading_state():
	# Set up a loading state
	menu._loading_started = true
	menu.loading_container.show()
	menu.loading_progress.value = 50
	menu.start_button.disabled = true
	
	# Call cleanup
	menu._cleanup_loading_state()
	
	# Verify everything is reset
	assert_false(menu._loading_started, "Loading started flag should be reset")
	assert_false(menu.loading_container.visible, "Loading container should be hidden")
	assert_eq(menu.loading_progress.value, 0, "Progress should be reset to 0")
	assert_false(menu.start_button.disabled, "Start button should be enabled")

func test_start_button_press():
	menu._start_scene_prefetch()
	await get_tree().process_frame
	
	# Simulate button press
	menu._on_start_game_button_pressed()
	
	# Scene change requested
	assert_not_null(menu.get_tree(), "Scene tree should exist")
