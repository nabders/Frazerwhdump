## WeaponBase - Base class for all weapons
## Handles cooldown, firing, and leveling
class_name WeaponBase
extends Node2D

# =============================================================================
# SIGNALS
# =============================================================================

signal fired
signal leveled_up(new_level: int)
signal cooldown_started(duration: float)

# =============================================================================
# EXPORTS
# =============================================================================

@export var weapon_data: WeaponData = null
@export var current_level: int = 1

# =============================================================================
# STATE
# =============================================================================

var owner_entity: Node2D = null
var stats_component: StatsComponent = null
var cooldown_timer: float = 0.0
var is_on_cooldown: bool = false

# Cached stats (updated on level up)
var cached_damage: int = 10
var cached_cooldown: float = 1.0
var cached_area: float = 1.0
var cached_amount: int = 1
var cached_knockback: float = 50.0

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_find_owner()
	_update_cached_stats()


func _process(delta: float) -> void:
	if is_on_cooldown:
		cooldown_timer -= delta
		if cooldown_timer <= 0:
			is_on_cooldown = false
			cooldown_timer = 0.0

	if not is_on_cooldown and _can_fire():
		_fire()

# =============================================================================
# SETUP
# =============================================================================

func _find_owner() -> void:
	# Walk up the tree to find the player/entity
	var parent := get_parent()
	while parent:
		if parent.is_in_group("player") or parent.is_in_group("enemy"):
			owner_entity = parent
			break
		parent = parent.get_parent()

	if owner_entity:
		stats_component = owner_entity.get_node_or_null("StatsComponent")


func setup(data: WeaponData, level: int = 1) -> void:
	weapon_data = data
	current_level = level
	_update_cached_stats()


func _update_cached_stats() -> void:
	if weapon_data:
		var stats := weapon_data.get_stats_at_level(current_level)
		cached_damage = stats.damage
		cached_cooldown = stats.cooldown
		cached_area = stats.area
		cached_amount = stats.amount
		cached_knockback = stats.knockback
	else:
		# Default values
		cached_damage = 10
		cached_cooldown = 1.0
		cached_area = 1.0
		cached_amount = 1
		cached_knockback = 50.0

	# Apply stat modifiers from owner
	if stats_component:
		cached_damage = int(cached_damage * stats_component.get_stat("damage"))
		cached_cooldown *= stats_component.get_cooldown_multiplier()
		cached_area *= stats_component.get_stat("area")

# =============================================================================
# FIRING
# =============================================================================

func _can_fire() -> bool:
	# Override in subclasses for additional conditions
	return GameManager.is_playing() and not is_on_cooldown


func _fire() -> void:
	# Override in subclasses to implement weapon behavior
	_start_cooldown()
	fired.emit()
	EventBus.weapon_fired.emit(self)


func _start_cooldown() -> void:
	is_on_cooldown = true
	cooldown_timer = cached_cooldown
	cooldown_started.emit(cached_cooldown)

# =============================================================================
# TARGETING
# =============================================================================

func _get_nearest_enemy() -> Node2D:
	if owner_entity == null:
		return null

	var enemies := get_tree().get_nodes_in_group("enemy")
	var nearest: Node2D = null
	var nearest_dist := INF

	for enemy in enemies:
		if not enemy is Node2D:
			continue
		if enemy.get("is_dead"):
			continue

		var dist := owner_entity.global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest = enemy

	return nearest


func _get_enemies_in_range(range_radius: float) -> Array[Node2D]:
	if owner_entity == null:
		return []

	var result: Array[Node2D] = []
	var enemies := get_tree().get_nodes_in_group("enemy")

	for enemy in enemies:
		if not enemy is Node2D:
			continue
		if enemy.get("is_dead"):
			continue

		var dist := owner_entity.global_position.distance_to(enemy.global_position)
		if dist <= range_radius:
			result.append(enemy)

	return result


func _get_aim_direction() -> Vector2:
	# Default: aim at nearest enemy, fallback to facing direction
	var nearest := _get_nearest_enemy()
	if nearest:
		return (nearest.global_position - owner_entity.global_position).normalized()

	# Fallback to input direction
	var input_dir := InputManager.get_aim_direction()
	if input_dir != Vector2.ZERO:
		return input_dir

	return Vector2.RIGHT

# =============================================================================
# LEVELING
# =============================================================================

func level_up() -> bool:
	if weapon_data and current_level >= weapon_data.max_level:
		return false

	current_level += 1
	_update_cached_stats()
	leveled_up.emit(current_level)
	EventBus.weapon_leveled_up.emit(weapon_data, current_level)
	return true


func is_max_level() -> bool:
	if weapon_data:
		return current_level >= weapon_data.max_level
	return current_level >= 8


func get_level() -> int:
	return current_level

# =============================================================================
# UTILITY
# =============================================================================

func get_damage() -> int:
	return cached_damage


func get_cooldown() -> float:
	return cached_cooldown


func get_cooldown_progress() -> float:
	if not is_on_cooldown:
		return 1.0
	return 1.0 - (cooldown_timer / cached_cooldown)
