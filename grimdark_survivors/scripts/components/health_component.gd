## HealthComponent - Manages HP, damage, healing, and death
## Attach to any entity that can take damage
class_name HealthComponent
extends Node

# =============================================================================
# SIGNALS
# =============================================================================

signal health_changed(current: int, maximum: int)
signal damage_taken(amount: int, source: Node)
signal healed(amount: int)
signal died
signal revived

# =============================================================================
# EXPORTS
# =============================================================================

@export var max_health: int = 100
@export var starting_health: int = -1  # -1 means use max_health
@export var invincibility_time: float = 0.0  # Seconds of invincibility after taking damage
@export var can_revive: bool = false
@export var revive_health_percent: float = 0.5

# =============================================================================
# STATE
# =============================================================================

var current_health: int = 0
var is_dead: bool = false
var is_invincible: bool = false
var revives_remaining: int = 0

var _invincibility_timer: float = 0.0

# Reference to the owner entity
var entity: Node = null

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	entity = get_parent()

	if starting_health < 0:
		current_health = max_health
	else:
		current_health = mini(starting_health, max_health)

	# Check for revivals from meta progression
	if entity.is_in_group("player"):
		revives_remaining = int(SaveManager.get_upgrade_bonus("revivals"))


func _process(delta: float) -> void:
	if is_invincible and _invincibility_timer > 0.0:
		_invincibility_timer -= delta
		if _invincibility_timer <= 0.0:
			is_invincible = false

# =============================================================================
# DAMAGE AND HEALING
# =============================================================================

func take_damage(amount: int, source: Node = null) -> void:
	if is_dead or is_invincible or amount <= 0:
		return

	var actual_damage := mini(amount, current_health)
	current_health -= actual_damage

	damage_taken.emit(actual_damage, source)
	health_changed.emit(current_health, max_health)

	# Broadcast damage event
	EventBus.damage_dealt.emit(actual_damage, entity.global_position if entity else Vector2.ZERO, false)

	# Apply invincibility frames
	if invincibility_time > 0.0:
		is_invincible = true
		_invincibility_timer = invincibility_time

	# Check for death
	if current_health <= 0:
		_handle_death()


func heal(amount: int) -> void:
	if is_dead or amount <= 0:
		return

	var actual_heal := mini(amount, max_health - current_health)
	if actual_heal > 0:
		current_health += actual_heal
		healed.emit(actual_heal)
		health_changed.emit(current_health, max_health)


func heal_percent(percent: float) -> void:
	var amount := int(max_health * percent)
	heal(amount)


func set_max_health(new_max: int, heal_to_new_max: bool = false) -> void:
	var old_max := max_health
	max_health = maxi(1, new_max)

	if heal_to_new_max and max_health > old_max:
		current_health += max_health - old_max

	# Clamp current health if max decreased
	current_health = mini(current_health, max_health)
	health_changed.emit(current_health, max_health)


func add_max_health(amount: int, heal_added: bool = true) -> void:
	set_max_health(max_health + amount, heal_added)

# =============================================================================
# DEATH AND REVIVAL
# =============================================================================

func _handle_death() -> void:
	if can_revive and revives_remaining > 0:
		_revive()
		return

	is_dead = true
	current_health = 0
	died.emit()

	# Broadcast death based on entity type
	if entity:
		if entity.is_in_group("player"):
			EventBus.player_died.emit()
		elif entity.is_in_group("enemy"):
			var xp_value: int = entity.get("xp_value") if entity.get("xp_value") else 1
			EventBus.enemy_killed.emit(entity, entity.global_position, xp_value)


func _revive() -> void:
	revives_remaining -= 1
	current_health = int(max_health * revive_health_percent)
	is_invincible = true
	_invincibility_timer = 2.0  # Extra invincibility on revive

	revived.emit()
	health_changed.emit(current_health, max_health)


func add_revive(count: int = 1) -> void:
	revives_remaining += count
	can_revive = true


func force_kill() -> void:
	is_invincible = false
	revives_remaining = 0
	can_revive = false
	take_damage(current_health + 1)

# =============================================================================
# QUERIES
# =============================================================================

func get_health_percent() -> float:
	if max_health <= 0:
		return 0.0
	return float(current_health) / float(max_health)


func is_full_health() -> bool:
	return current_health >= max_health


func is_low_health(threshold: float = 0.3) -> bool:
	return get_health_percent() <= threshold


func get_missing_health() -> int:
	return max_health - current_health

# =============================================================================
# INVINCIBILITY
# =============================================================================

func set_invincible(duration: float) -> void:
	is_invincible = true
	_invincibility_timer = maxf(_invincibility_timer, duration)


func clear_invincibility() -> void:
	is_invincible = false
	_invincibility_timer = 0.0
