## CameraController - Smooth following camera with shake support
## Attach to Camera2D node
class_name CameraController
extends Camera2D

# =============================================================================
# EXPORTS
# =============================================================================

@export var follow_target: Node2D = null
@export var follow_smoothing: float = 5.0
@export var look_ahead_distance: float = 50.0
@export var look_ahead_smoothing: float = 3.0

# Shake settings
@export var max_shake_offset: float = 20.0
@export var shake_decay_rate: float = 5.0

# =============================================================================
# STATE
# =============================================================================

var shake_intensity: float = 0.0
var shake_offset: Vector2 = Vector2.ZERO
var look_ahead_offset: Vector2 = Vector2.ZERO
var target_look_ahead: Vector2 = Vector2.ZERO

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_connect_signals()

	# Find player if not set
	if follow_target == null:
		await get_tree().process_frame
		_find_player()


func _process(delta: float) -> void:
	_update_follow(delta)
	_update_shake(delta)
	_update_look_ahead(delta)

	# Apply final position
	if follow_target:
		var target_pos := follow_target.global_position + look_ahead_offset + shake_offset
		global_position = global_position.lerp(target_pos, follow_smoothing * delta)

# =============================================================================
# SETUP
# =============================================================================

func _connect_signals() -> void:
	EventBus.screen_shake_requested.connect(_on_shake_requested)
	EventBus.run_started.connect(_on_run_started)


func _find_player() -> void:
	var player := GameManager.get_player()
	if player:
		follow_target = player
		global_position = player.global_position


func _on_run_started() -> void:
	# Re-find player when run starts
	call_deferred("_find_player")

# =============================================================================
# FOLLOW
# =============================================================================

func _update_follow(_delta: float) -> void:
	if follow_target == null:
		_find_player()


func set_follow_target(target: Node2D) -> void:
	follow_target = target
	if target:
		global_position = target.global_position

# =============================================================================
# LOOK AHEAD
# =============================================================================

func _update_look_ahead(delta: float) -> void:
	if follow_target == null:
		return

	# Get movement direction from input
	var input_dir := InputManager.get_movement_input()

	if input_dir != Vector2.ZERO:
		target_look_ahead = input_dir.normalized() * look_ahead_distance
	else:
		target_look_ahead = Vector2.ZERO

	look_ahead_offset = look_ahead_offset.lerp(target_look_ahead, look_ahead_smoothing * delta)

# =============================================================================
# SCREEN SHAKE
# =============================================================================

func _on_shake_requested(intensity: float, duration: float) -> void:
	# Check if screen shake is enabled in settings
	if not SaveManager.get_setting("screen_shake"):
		return

	shake_intensity = maxf(shake_intensity, intensity)

	# Auto-decay after duration
	get_tree().create_timer(duration).timeout.connect(
		func(): shake_intensity = 0.0,
		CONNECT_ONE_SHOT
	)


func _update_shake(delta: float) -> void:
	if shake_intensity > 0:
		# Random offset based on intensity
		shake_offset = Vector2(
			randf_range(-1, 1) * shake_intensity * max_shake_offset,
			randf_range(-1, 1) * shake_intensity * max_shake_offset
		)

		# Decay shake
		shake_intensity = maxf(0, shake_intensity - shake_decay_rate * delta)
	else:
		shake_offset = Vector2.ZERO


func shake(intensity: float, duration: float = 0.2) -> void:
	_on_shake_requested(intensity, duration)

# =============================================================================
# UTILITY
# =============================================================================

func snap_to_target() -> void:
	if follow_target:
		global_position = follow_target.global_position
		look_ahead_offset = Vector2.ZERO


func get_viewport_rect_world() -> Rect2:
	var viewport_size := get_viewport_rect().size / zoom
	var top_left := global_position - viewport_size / 2
	return Rect2(top_left, viewport_size)
