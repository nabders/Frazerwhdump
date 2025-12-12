## StateMachine - Manages state transitions and updates
## Add as a child node and populate with State nodes
class_name StateMachine
extends Node

# =============================================================================
# SIGNALS
# =============================================================================

signal state_changed(old_state: State, new_state: State)
signal state_entered(state: State)
signal state_exited(state: State)

# =============================================================================
# EXPORTS
# =============================================================================

@export var initial_state: State = null
@export var debug_mode: bool = false

# =============================================================================
# STATE
# =============================================================================

var current_state: State = null
var previous_state: State = null
var states: Dictionary = {}  # state_name: State

# Reference to the entity this state machine controls
var entity: Node = null

# State history for debugging
var state_history: Array[String] = []
const MAX_HISTORY_SIZE: int = 10

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	entity = get_parent()

	# Register all child states
	for child in get_children():
		if child is State:
			_register_state(child)

	# Initialize with starting state
	if initial_state:
		_change_state_internal(initial_state)
	elif states.size() > 0:
		# Use first state if no initial state set
		_change_state_internal(states.values()[0])


func _process(delta: float) -> void:
	if current_state:
		current_state.update(delta)


func _physics_process(delta: float) -> void:
	if current_state:
		current_state.physics_update(delta)


func _unhandled_input(event: InputEvent) -> void:
	if current_state:
		current_state.handle_input(event)

# =============================================================================
# STATE REGISTRATION
# =============================================================================

func _register_state(state: State) -> void:
	states[state.name] = state
	state.state_machine = self
	state.entity = entity

	if debug_mode:
		print("[StateMachine] Registered state: %s" % state.name)


func add_state(state: State) -> void:
	add_child(state)
	_register_state(state)


func remove_state(state_name: String) -> void:
	if state_name in states:
		var state: State = states[state_name]
		states.erase(state_name)
		state.queue_free()

# =============================================================================
# STATE TRANSITIONS
# =============================================================================

func change_state(new_state_name: String, msg: Dictionary = {}) -> void:
	if new_state_name not in states:
		push_error("[StateMachine] State not found: %s" % new_state_name)
		return

	var new_state: State = states[new_state_name]
	_change_state_internal(new_state, msg)


func change_state_to(new_state: State, msg: Dictionary = {}) -> void:
	if new_state == null:
		push_error("[StateMachine] Attempted to change to null state")
		return

	_change_state_internal(new_state, msg)


func _change_state_internal(new_state: State, msg: Dictionary = {}) -> void:
	if new_state == current_state:
		return

	# Exit current state
	if current_state:
		current_state.exit()
		state_exited.emit(current_state)
		previous_state = current_state

		if debug_mode:
			print("[StateMachine] Exited: %s" % current_state.name)

	# Track history
	if current_state:
		state_history.append(current_state.name)
		if state_history.size() > MAX_HISTORY_SIZE:
			state_history.pop_front()

	# Change to new state
	var old_state := current_state
	current_state = new_state

	# Enter new state
	current_state.enter(msg)
	state_entered.emit(current_state)
	state_changed.emit(old_state, current_state)

	if debug_mode:
		print("[StateMachine] Entered: %s" % current_state.name)

# =============================================================================
# STATE QUERIES
# =============================================================================

func get_current_state() -> State:
	return current_state


func get_current_state_name() -> String:
	return current_state.name if current_state else ""


func get_previous_state() -> State:
	return previous_state


func get_previous_state_name() -> String:
	return previous_state.name if previous_state else ""


func is_in_state(state_name: String) -> bool:
	return current_state != null and current_state.name == state_name


func has_state(state_name: String) -> bool:
	return state_name in states


func get_state(state_name: String) -> State:
	return states.get(state_name, null)


func get_all_states() -> Array:
	return states.values()


func get_state_history() -> Array[String]:
	return state_history.duplicate()

# =============================================================================
# UTILITY
# =============================================================================

func return_to_previous_state(msg: Dictionary = {}) -> void:
	if previous_state:
		change_state_to(previous_state, msg)


func restart_current_state(msg: Dictionary = {}) -> void:
	if current_state:
		current_state.exit()
		current_state.enter(msg)


func get_time_in_current_state() -> float:
	if current_state:
		return current_state.get_time_in_state()
	return 0.0
