## MovementComponent - Handles velocity, acceleration, and knockback
## Attach to any entity that needs to move
class_name MovementComponent
extends Node

# =============================================================================
# SIGNALS
# =============================================================================

signal velocity_changed(new_velocity: Vector2)
signal knockback_started
signal knockback_ended
signal movement_locked
signal movement_unlocked

# =============================================================================
# EXPORTS
# =============================================================================

@export var max_speed: float = 200.0
@export var acceleration: float = 1500.0
@export var friction: float = 1000.0
@export var use_acceleration: bool = true  # If false, movement is instant

# Knockback settings
@export var knockback_resistance: float = 0.0  # 0.0 = full knockback, 1.0 = immune
@export var knockback_decay: float = 500.0  # How fast knockback velocity decays

# =============================================================================
# STATE
# =============================================================================

var velocity: Vector2 = Vector2.ZERO
var knockback_velocity: Vector2 = Vector2.ZERO
var movement_direction: Vector2 = Vector2.ZERO
var facing_direction: Vector2 = Vector2.RIGHT

var is_movement_locked: bool = false
var is_being_knocked_back: bool = false

# Speed modifiers (multiplicative)
var speed_multiplier: float = 1.0

# Reference to the entity (should be CharacterBody2D)
var entity: CharacterBody2D = null

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	entity = get_parent() as CharacterBody2D
	if entity == null:
		push_warning("[MovementComponent] Parent is not a CharacterBody2D")


func _physics_process(delta: float) -> void:
	if entity == null:
		return

	_process_movement(delta)
	_process_knockback(delta)
	_apply_velocity()

# =============================================================================
# MOVEMENT PROCESSING
# =============================================================================

func _process_movement(delta: float) -> void:
	if is_movement_locked:
		# Apply friction when locked
		if use_acceleration:
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
		else:
			velocity = Vector2.ZERO
		return

	var target_velocity := movement_direction * max_speed * speed_multiplier

	if use_acceleration:
		if movement_direction != Vector2.ZERO:
			# Accelerate toward target
			velocity = velocity.move_toward(target_velocity, acceleration * delta)
		else:
			# Apply friction when not moving
			velocity = velocity.move_toward(Vector2.ZERO, friction * delta)
	else:
		# Instant movement
		velocity = target_velocity


func _process_knockback(delta: float) -> void:
	if knockback_velocity == Vector2.ZERO:
		if is_being_knocked_back:
			is_being_knocked_back = false
			knockback_ended.emit()
		return

	knockback_velocity = knockback_velocity.move_toward(Vector2.ZERO, knockback_decay * delta)


func _apply_velocity() -> void:
	var total_velocity := velocity + knockback_velocity
	entity.velocity = total_velocity
	entity.move_and_slide()

	velocity_changed.emit(total_velocity)

# =============================================================================
# MOVEMENT CONTROL
# =============================================================================

func set_movement_direction(direction: Vector2) -> void:
	movement_direction = direction.normalized() if direction.length() > 1.0 else direction

	# Update facing direction if moving
	if direction != Vector2.ZERO:
		facing_direction = direction.normalized()


func stop() -> void:
	movement_direction = Vector2.ZERO
	velocity = Vector2.ZERO


func lock_movement() -> void:
	is_movement_locked = true
	movement_direction = Vector2.ZERO
	movement_locked.emit()


func unlock_movement() -> void:
	is_movement_locked = false
	movement_unlocked.emit()

# =============================================================================
# KNOCKBACK
# =============================================================================

func apply_knockback(knockback: Vector2) -> void:
	if knockback_resistance >= 1.0:
		return

	var final_knockback := knockback * (1.0 - knockback_resistance)
	knockback_velocity += final_knockback

	if not is_being_knocked_back:
		is_being_knocked_back = true
		knockback_started.emit()

	EventBus.knockback_applied.emit(entity, knockback.normalized(), knockback.length())


func clear_knockback() -> void:
	knockback_velocity = Vector2.ZERO
	if is_being_knocked_back:
		is_being_knocked_back = false
		knockback_ended.emit()

# =============================================================================
# SPEED MODIFIERS
# =============================================================================

func set_speed_multiplier(multiplier: float) -> void:
	speed_multiplier = maxf(0.0, multiplier)


func add_speed_multiplier(amount: float) -> void:
	speed_multiplier = maxf(0.0, speed_multiplier + amount)


func reset_speed_multiplier() -> void:
	speed_multiplier = 1.0


func get_current_max_speed() -> float:
	return max_speed * speed_multiplier

# =============================================================================
# QUERIES
# =============================================================================

func get_velocity() -> Vector2:
	return velocity + knockback_velocity


func get_speed() -> float:
	return get_velocity().length()


func is_moving() -> bool:
	return velocity.length() > 10.0


func get_facing_direction() -> Vector2:
	return facing_direction


func is_locked() -> bool:
	return is_movement_locked

# =============================================================================
# TELEPORTATION
# =============================================================================

func teleport_to(position: Vector2) -> void:
	if entity:
		entity.global_position = position
		velocity = Vector2.ZERO
		knockback_velocity = Vector2.ZERO


func move_by(offset: Vector2) -> void:
	if entity:
		entity.global_position += offset
