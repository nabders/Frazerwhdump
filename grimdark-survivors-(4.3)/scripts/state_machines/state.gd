## State - Base class for all states in the state machine
## Extend this class to create specific states
class_name State
extends Node

# =============================================================================
# REFERENCES
# =============================================================================

## Reference to the state machine managing this state
var state_machine: StateMachine = null

## Reference to the entity this state controls (set by state machine)
var entity: Node = null

# =============================================================================
# STATE
# =============================================================================

## Time since entering this state
var time_in_state: float = 0.0

## Whether this state can be interrupted by other states
var can_be_interrupted: bool = true

## Priority for state transitions (higher = more priority)
var priority: int = 0

# =============================================================================
# VIRTUAL METHODS - Override these in subclasses
# =============================================================================

func enter(msg: Dictionary = {}) -> void:
	## Called when entering this state
	## msg: Optional data passed from the previous state
	time_in_state = 0.0


func exit() -> void:
	## Called when exiting this state
	pass


func update(delta: float) -> void:
	## Called every frame (from _process)
	time_in_state += delta


func physics_update(delta: float) -> void:
	## Called every physics frame (from _physics_process)
	pass


func handle_input(event: InputEvent) -> void:
	## Called for unhandled input events
	pass

# =============================================================================
# TRANSITION HELPERS
# =============================================================================

func transition_to(state_name: String, msg: Dictionary = {}) -> void:
	## Convenience method to transition to another state
	if state_machine:
		state_machine.change_state(state_name, msg)


func return_to_previous() -> void:
	## Return to the previous state
	if state_machine:
		state_machine.return_to_previous_state()

# =============================================================================
# QUERIES
# =============================================================================

func get_time_in_state() -> float:
	return time_in_state


func is_active() -> bool:
	return state_machine != null and state_machine.current_state == self

# =============================================================================
# ANIMATION HELPERS
# =============================================================================

func play_animation(anim_name: String) -> void:
	## Convenience method to play animation on the entity
	if entity == null:
		return

	var anim_player := entity.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if anim_player and anim_player.has_animation(anim_name):
		anim_player.play(anim_name)


func play_sprite_animation(anim_name: String) -> void:
	## Convenience method to play AnimatedSprite2D animation
	if entity == null:
		return

	var sprite := entity.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)


func is_animation_finished(anim_name: String = "") -> bool:
	## Check if current animation is finished
	if entity == null:
		return true

	var anim_player := entity.get_node_or_null("AnimationPlayer") as AnimationPlayer
	if anim_player:
		if anim_name.is_empty():
			return not anim_player.is_playing()
		return anim_player.current_animation != anim_name or not anim_player.is_playing()

	return true

# =============================================================================
# COMPONENT ACCESS
# =============================================================================

func get_health_component() -> HealthComponent:
	if entity:
		return entity.get_node_or_null("HealthComponent") as HealthComponent
	return null


func get_movement_component() -> MovementComponent:
	if entity:
		return entity.get_node_or_null("MovementComponent") as MovementComponent
	return null


func get_stats_component() -> StatsComponent:
	if entity:
		return entity.get_node_or_null("StatsComponent") as StatsComponent
	return null
