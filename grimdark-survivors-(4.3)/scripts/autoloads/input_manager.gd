## InputManager - Handles input state, buffering, and remapping
## Provides centralized input querying for keyboard-only controls
extends Node

# =============================================================================
# CONSTANTS
# =============================================================================

const INPUT_BUFFER_TIME: float = 0.15  # Seconds to buffer inputs

# Input action names (matching project.godot)
const ACTION_MOVE_UP: String = "move_up"
const ACTION_MOVE_DOWN: String = "move_down"
const ACTION_MOVE_LEFT: String = "move_left"
const ACTION_MOVE_RIGHT: String = "move_right"
const ACTION_DODGE: String = "dodge"
const ACTION_INTERACT: String = "interact"
const ACTION_CANCEL: String = "cancel"
const ACTION_PAUSE: String = "pause"

# Quick select actions
const ACTION_SELECT_PREFIX: String = "select_"

# =============================================================================
# STATE
# =============================================================================

var movement_input: Vector2 = Vector2.ZERO
var input_disabled: bool = false

# Input buffering
var buffered_actions: Dictionary = {}  # action_name: timestamp

# Last input direction (for aim direction when not moving)
var last_movement_direction: Vector2 = Vector2.RIGHT

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	print("[InputManager] Initialized - Keyboard only mode")


func _process(_delta: float) -> void:
	if input_disabled:
		movement_input = Vector2.ZERO
		return

	_update_movement_input()
	_clean_expired_buffers()


func _unhandled_input(event: InputEvent) -> void:
	if input_disabled:
		return

	# Handle pause regardless of game state
	if event.is_action_pressed(ACTION_PAUSE):
		GameManager.toggle_pause()
		get_viewport().set_input_as_handled()
		return

	# Buffer certain actions
	if event.is_action_pressed(ACTION_DODGE):
		_buffer_action(ACTION_DODGE)
	elif event.is_action_pressed(ACTION_INTERACT):
		_buffer_action(ACTION_INTERACT)
	elif event.is_action_pressed(ACTION_CANCEL):
		_buffer_action(ACTION_CANCEL)

	# Quick select buffering
	for i in range(1, 7):
		var action := ACTION_SELECT_PREFIX + str(i)
		if event.is_action_pressed(action):
			_buffer_action(action)

# =============================================================================
# MOVEMENT INPUT
# =============================================================================

func _update_movement_input() -> void:
	movement_input = Vector2.ZERO

	if Input.is_action_pressed(ACTION_MOVE_RIGHT):
		movement_input.x += 1.0
	if Input.is_action_pressed(ACTION_MOVE_LEFT):
		movement_input.x -= 1.0
	if Input.is_action_pressed(ACTION_MOVE_DOWN):
		movement_input.y += 1.0
	if Input.is_action_pressed(ACTION_MOVE_UP):
		movement_input.y -= 1.0

	# Normalize for consistent diagonal speed
	if movement_input.length() > 1.0:
		movement_input = movement_input.normalized()

	# Update last direction if moving
	if movement_input != Vector2.ZERO:
		last_movement_direction = movement_input.normalized()


func get_movement_input() -> Vector2:
	return movement_input


func get_aim_direction() -> Vector2:
	# In keyboard-only mode, aim direction is based on movement
	if movement_input != Vector2.ZERO:
		return movement_input.normalized()
	return last_movement_direction


func is_moving() -> bool:
	return movement_input != Vector2.ZERO

# =============================================================================
# ACTION QUERIES
# =============================================================================

func is_action_pressed(action: String) -> bool:
	if input_disabled:
		return false
	return Input.is_action_pressed(action)


func is_action_just_pressed(action: String) -> bool:
	if input_disabled:
		return false
	return Input.is_action_just_pressed(action)


func is_dodge_pressed() -> bool:
	return is_action_just_pressed(ACTION_DODGE) or consume_buffered_action(ACTION_DODGE)


func is_interact_pressed() -> bool:
	return is_action_just_pressed(ACTION_INTERACT) or consume_buffered_action(ACTION_INTERACT)


func is_cancel_pressed() -> bool:
	return is_action_just_pressed(ACTION_CANCEL) or consume_buffered_action(ACTION_CANCEL)


func get_quick_select() -> int:
	## Returns 1-6 if a quick select key is pressed, 0 otherwise
	for i in range(1, 7):
		var action := ACTION_SELECT_PREFIX + str(i)
		if is_action_just_pressed(action) or consume_buffered_action(action):
			return i
	return 0

# =============================================================================
# INPUT BUFFERING
# =============================================================================

func _buffer_action(action: String) -> void:
	buffered_actions[action] = Time.get_ticks_msec() / 1000.0


func consume_buffered_action(action: String) -> bool:
	if action not in buffered_actions:
		return false

	var buffer_time: float = buffered_actions[action]
	var current_time := Time.get_ticks_msec() / 1000.0

	if current_time - buffer_time <= INPUT_BUFFER_TIME:
		buffered_actions.erase(action)
		return true

	return false


func is_action_buffered(action: String) -> bool:
	if action not in buffered_actions:
		return false

	var buffer_time: float = buffered_actions[action]
	var current_time := Time.get_ticks_msec() / 1000.0

	return current_time - buffer_time <= INPUT_BUFFER_TIME


func _clean_expired_buffers() -> void:
	var current_time := Time.get_ticks_msec() / 1000.0
	var expired: Array[String] = []

	for action in buffered_actions:
		if current_time - buffered_actions[action] > INPUT_BUFFER_TIME:
			expired.append(action)

	for action in expired:
		buffered_actions.erase(action)


func clear_all_buffers() -> void:
	buffered_actions.clear()

# =============================================================================
# INPUT STATE CONTROL
# =============================================================================

func disable_input() -> void:
	input_disabled = true
	movement_input = Vector2.ZERO
	clear_all_buffers()


func enable_input() -> void:
	input_disabled = false


func is_input_enabled() -> bool:
	return not input_disabled

# =============================================================================
# MENU NAVIGATION
# =============================================================================

func get_menu_direction() -> Vector2:
	## Returns direction for menu navigation (non-normalized, for discrete steps)
	var direction := Vector2.ZERO

	if Input.is_action_just_pressed(ACTION_MOVE_UP):
		direction.y -= 1
	if Input.is_action_just_pressed(ACTION_MOVE_DOWN):
		direction.y += 1
	if Input.is_action_just_pressed(ACTION_MOVE_LEFT):
		direction.x -= 1
	if Input.is_action_just_pressed(ACTION_MOVE_RIGHT):
		direction.x += 1

	return direction


func is_menu_confirm() -> bool:
	return is_interact_pressed()


func is_menu_cancel() -> bool:
	return is_cancel_pressed()

# =============================================================================
# INPUT REMAPPING
# =============================================================================

func get_action_keys(action: String) -> Array[String]:
	## Returns human-readable key names for an action
	var keys: Array[String] = []
	var events := InputMap.action_get_events(action)

	for event in events:
		if event is InputEventKey:
			keys.append(OS.get_keycode_string(event.physical_keycode))

	return keys


func remap_action(action: String, new_event: InputEvent) -> void:
	## Removes existing events and adds a new one
	InputMap.action_erase_events(action)
	InputMap.action_add_event(action, new_event)
	# Save remapping would go through SaveManager


func reset_to_defaults() -> void:
	## Reloads input map from project settings
	InputMap.load_from_project_settings()
