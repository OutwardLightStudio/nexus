extends Control
class_name TouchControls

signal thrust_pressed
signal thrust_released
signal rotate_left_pressed
signal rotate_left_released
signal rotate_right_pressed
signal rotate_right_released
signal boost_pressed
signal boost_released

@onready var thrust_button = $VBoxContainer/ThrustButton
@onready var rotate_left_button = $VBoxContainer/RotationContainer/RotateLeftButton
@onready var rotate_right_button = $VBoxContainer/RotationContainer/RotateRightButton
@onready var boost_button = $BoostControl/E_button

# Dictionary to store button configurations
var buttons = {}
# Dictionary to store active touch events and their affected buttons
var active_touches = {}
# Touch detection radius in pixels - increased to allow easier simultaneous button presses
var touch_radius: float = 75.0

# Colors
var button_normal_color = Color("#6b6b6b")
var rotate_normal_color = Color("#5d5d5d")
var button_pressed_color = Color("#8c8c8c")
var background_color = Color("#44444480") # With 50% transparency

func _ready():
    # Initialize button configurations
    buttons = {
        thrust_button: {
            "active": false,
            "press": _on_thrust_button_pressed,
            "release": _on_thrust_button_released
        },
        rotate_left_button: {
            "active": false,
            "press": _on_rotate_left_button_pressed,
            "release": _on_rotate_left_button_released
        },
        rotate_right_button: {
            "active": false,
            "press": _on_rotate_right_button_pressed,
            "release": _on_rotate_right_button_released
        },
        boost_button: {
            "active": false,
            "press": _on_boost_button_pressed,
            "release": _on_boost_button_released
        }
    }
    
    # Connect button signals for traditional clicks
    thrust_button.button_down.connect(_on_thrust_button_pressed)
    thrust_button.button_up.connect(_on_thrust_button_released)
    rotate_left_button.button_down.connect(_on_rotate_left_button_pressed)
    rotate_left_button.button_up.connect(_on_rotate_left_button_released)
    rotate_right_button.button_down.connect(_on_rotate_right_button_pressed)
    rotate_right_button.button_up.connect(_on_rotate_right_button_released)
    
    # Connect boost button signals
    if boost_button:
        boost_button.pressed_boost.connect(_on_boost_button_pressed)
        boost_button.released_boost.connect(_on_boost_button_released)
    
    # Set initial appearance
    thrust_button.add_theme_color_override("icon_normal_color", button_normal_color)
    thrust_button.add_theme_color_override("icon_pressed_color", button_pressed_color)
    rotate_left_button.add_theme_color_override("icon_normal_color", rotate_normal_color)
    rotate_left_button.add_theme_color_override("icon_pressed_color", button_pressed_color)
    rotate_right_button.add_theme_color_override("icon_normal_color", rotate_normal_color)
    rotate_right_button.add_theme_color_override("icon_pressed_color", button_pressed_color)

func show_boost_button():
    if boost_button:
        boost_button.visible = true

func hide_boost_button():
    if boost_button:
        boost_button.visible = false

# Check if a touch circle intersects with a button's rect
func circle_intersects_rect(circle_pos: Vector2, radius: float, rect: Rect2) -> bool:
    # Find the closest point on the rectangle to the circle's center
    var closest_x = clampf(circle_pos.x, rect.position.x, rect.position.x + rect.size.x)
    var closest_y = clampf(circle_pos.y, rect.position.y, rect.position.y + rect.size.y)
    var closest_point = Vector2(closest_x, closest_y)
    
    # If the distance between the closest point and circle center is less than radius,
    # then there is an intersection
    return circle_pos.distance_to(closest_point) <= radius

# Handle button states for circular touch detection
func handle_button_state(button: Control, touch_position: Vector2, event: InputEvent) -> void:
    var button_rect = button.get_global_rect()
    var touches_button = circle_intersects_rect(touch_position, touch_radius, button_rect)
    var button_data = buttons[button]
    
    if touches_button:
        if not button_data["active"] and event is InputEventScreenTouch and event.pressed:
            button_data["active"] = true
            # Add this button to the list of buttons affected by this touch
            if not active_touches.has(event.index):
                active_touches[event.index] = []
            active_touches[event.index].append(button)
            button_data["press"].call()
    else:
        # If the touch is released and this button was affected by it
        if event is InputEventScreenTouch and not event.pressed:
            if active_touches.has(event.index) and button in active_touches[event.index]:
                button_data["active"] = false
                active_touches[event.index].erase(button)
                if active_touches[event.index].is_empty():
                    active_touches.erase(event.index)
                button_data["release"].call()

func _input(event):
    if event is InputEventScreenTouch or event is InputEventScreenDrag:
        var touch_position = event.position
        
        # Check if touch is on this control area
        if get_global_rect().has_point(touch_position):
            # Process each button for possible intersection
            for button in buttons.keys():
                handle_button_state(button, touch_position, event)
            
            # Handle touch release
            if event is InputEventScreenTouch and not event.pressed:
                # Release all buttons associated with this touch
                if active_touches.has(event.index):
                    for button in active_touches[event.index]:
                        buttons[button]["active"] = false
                        buttons[button]["release"].call()
                    active_touches.erase(event.index)

# Button press/release handlers
func _on_thrust_button_pressed():
    thrust_button.button_pressed = true
    Input.action_press("thrust")
    emit_signal("thrust_pressed")

func _on_thrust_button_released():
    thrust_button.button_pressed = false
    Input.action_release("thrust")
    emit_signal("thrust_released")

func _on_rotate_left_button_pressed():
    rotate_left_button.button_pressed = true
    Input.action_press("rotate_left")
    emit_signal("rotate_left_pressed")

func _on_rotate_left_button_released():
    rotate_left_button.button_pressed = false
    Input.action_release("rotate_left")
    emit_signal("rotate_left_released")

func _on_rotate_right_button_pressed():
    rotate_right_button.button_pressed = true
    Input.action_press("rotate_right")
    emit_signal("rotate_right_pressed")

func _on_rotate_right_button_released():
    rotate_right_button.button_pressed = false
    Input.action_release("rotate_right")
    emit_signal("rotate_right_released")

func _on_boost_button_pressed():
    Input.action_press("boost")
    emit_signal("boost_pressed")

func _on_boost_button_released():
    Input.action_release("boost")
    emit_signal("boost_released")
