## EnemySpawner - Manages enemy wave spawning
## Spawns enemies around the player based on time progression
class_name EnemySpawner
extends Node

# =============================================================================
# CONSTANTS
# =============================================================================

const MIN_SPAWN_DISTANCE: float = 400.0  # Minimum distance from player
const MAX_SPAWN_DISTANCE: float = 600.0  # Maximum distance from player
const SPAWN_CHECK_INTERVAL: float = 0.5  # How often to check for spawning

# =============================================================================
# EXPORTS
# =============================================================================

@export var enemy_scene: PackedScene = null
@export var max_enemies: int = 200
@export var base_spawn_rate: float = 1.0  # Enemies per second at start
@export var spawn_rate_increase: float = 0.2  # Additional per minute
@export var enabled: bool = true

# =============================================================================
# STATE
# =============================================================================

var spawn_timer: float = 0.0
var spawn_check_timer: float = 0.0
var current_enemy_count: int = 0
var total_spawned: int = 0
var player: Node2D = null
var enemies_container: Node2D = null

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_connect_signals()
	call_deferred("_find_references")


func _process(delta: float) -> void:
	if not enabled or not GameManager.is_playing():
		return

	if player == null:
		_find_references()
		return

	spawn_timer += delta
	spawn_check_timer += delta

	if spawn_check_timer >= SPAWN_CHECK_INTERVAL:
		spawn_check_timer = 0.0
		_check_spawn()

# =============================================================================
# SETUP
# =============================================================================

func _connect_signals() -> void:
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.run_started.connect(_on_run_started)
	EventBus.run_ended.connect(_on_run_ended)


func _find_references() -> void:
	player = GameManager.get_player()

	# Find enemies container in main scene
	var main := get_tree().get_first_node_in_group("main")
	if main and main.has_method("get_enemies_container"):
		enemies_container = main.get_enemies_container()
	else:
		# Fallback: create container as sibling
		enemies_container = get_parent().get_node_or_null("Enemies")
		if enemies_container == null:
			enemies_container = Node2D.new()
			enemies_container.name = "Enemies"
			get_parent().add_child(enemies_container)

# =============================================================================
# SPAWNING
# =============================================================================

func _check_spawn() -> void:
	if current_enemy_count >= max_enemies:
		return

	var current_spawn_rate := _get_current_spawn_rate()
	var spawn_interval := 1.0 / current_spawn_rate

	while spawn_timer >= spawn_interval and current_enemy_count < max_enemies:
		spawn_timer -= spawn_interval
		_spawn_enemy()


func _spawn_enemy() -> void:
	if enemy_scene == null or player == null or enemies_container == null:
		return

	var spawn_pos := _get_spawn_position()
	if spawn_pos == Vector2.INF:
		return  # No valid spawn position

	var enemy: EnemyBase = enemy_scene.instantiate()
	enemy.global_position = spawn_pos
	enemy.spawn_minute = GameManager.current_minute

	enemies_container.add_child(enemy)
	current_enemy_count += 1
	total_spawned += 1

	EventBus.enemy_spawned.emit(enemy)


func _get_spawn_position() -> Vector2:
	if player == null:
		return Vector2.INF

	# Try to find a valid spawn position
	for attempt in 10:
		var angle := randf() * TAU
		var distance := randf_range(MIN_SPAWN_DISTANCE, MAX_SPAWN_DISTANCE)
		var offset := Vector2(cos(angle), sin(angle)) * distance
		var spawn_pos := player.global_position + offset

		# Could add additional checks here (e.g., not spawning in walls)
		return spawn_pos

	return Vector2.INF


func _get_current_spawn_rate() -> float:
	var minute := GameManager.current_minute
	return base_spawn_rate + (spawn_rate_increase * minute)

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_enemy_killed(_enemy: Node, _position: Vector2, _xp_value: int) -> void:
	current_enemy_count = maxi(0, current_enemy_count - 1)


func _on_run_started() -> void:
	enabled = true
	current_enemy_count = 0
	total_spawned = 0
	spawn_timer = 0.0
	_find_references()


func _on_run_ended(_victory: bool, _stats: Dictionary) -> void:
	enabled = false

# =============================================================================
# UTILITY
# =============================================================================

func spawn_at_position(pos: Vector2) -> EnemyBase:
	if enemy_scene == null:
		return null

	var enemy: EnemyBase = enemy_scene.instantiate()
	enemy.global_position = pos
	enemy.spawn_minute = GameManager.current_minute

	if enemies_container:
		enemies_container.add_child(enemy)
	else:
		add_child(enemy)

	current_enemy_count += 1
	total_spawned += 1
	return enemy


func clear_all_enemies() -> void:
	if enemies_container:
		for child in enemies_container.get_children():
			child.queue_free()
	current_enemy_count = 0


func get_enemy_count() -> int:
	return current_enemy_count


func set_spawn_rate(rate: float) -> void:
	base_spawn_rate = rate
