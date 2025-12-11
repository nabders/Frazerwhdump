## StatsComponent - Manages all modifiable stats with base values and modifiers
## Attach to any entity that needs stats (player, enemies, weapons)
class_name StatsComponent
extends Node

# =============================================================================
# SIGNALS
# =============================================================================

signal stat_changed(stat_name: String, old_value: float, new_value: float)
signal modifier_added(stat_name: String, modifier_id: String)
signal modifier_removed(stat_name: String, modifier_id: String)

# =============================================================================
# STAT NAMES CONSTANTS
# =============================================================================

const STAT_MAX_HEALTH: String = "max_health"
const STAT_MOVE_SPEED: String = "move_speed"
const STAT_DAMAGE: String = "damage"
const STAT_ATTACK_SPEED: String = "attack_speed"
const STAT_CRIT_CHANCE: String = "crit_chance"
const STAT_CRIT_DAMAGE: String = "crit_damage"
const STAT_ARMOR: String = "armor"
const STAT_XP_GAIN: String = "xp_gain"
const STAT_PICKUP_RADIUS: String = "pickup_radius"
const STAT_LUCK: String = "luck"
const STAT_COOLDOWN_REDUCTION: String = "cooldown_reduction"
const STAT_AREA: String = "area"
const STAT_PROJECTILE_COUNT: String = "projectile_count"
const STAT_PROJECTILE_SPEED: String = "projectile_speed"
const STAT_DURATION: String = "duration"
const STAT_LIFESTEAL: String = "lifesteal"
const STAT_REGEN: String = "regen"
const STAT_GOLD_GAIN: String = "gold_gain"

# =============================================================================
# EXPORTS
# =============================================================================

@export var base_stats: Dictionary = {
	STAT_MAX_HEALTH: 100.0,
	STAT_MOVE_SPEED: 200.0,
	STAT_DAMAGE: 10.0,
	STAT_ATTACK_SPEED: 1.0,
	STAT_CRIT_CHANCE: 0.05,
	STAT_CRIT_DAMAGE: 1.5,
	STAT_ARMOR: 0.0,
	STAT_XP_GAIN: 1.0,
	STAT_PICKUP_RADIUS: 50.0,
	STAT_LUCK: 1.0,
	STAT_COOLDOWN_REDUCTION: 0.0,
	STAT_AREA: 1.0,
	STAT_PROJECTILE_COUNT: 0.0,  # Additive bonus
	STAT_PROJECTILE_SPEED: 1.0,
	STAT_DURATION: 1.0,
	STAT_LIFESTEAL: 0.0,
	STAT_REGEN: 0.0,
	STAT_GOLD_GAIN: 1.0
}

# =============================================================================
# STATE
# =============================================================================

# Modifiers are stored as: {stat_name: {modifier_id: {type: "add/mult", value: float}}}
var modifiers: Dictionary = {}

# Cached final values (recalculated when modifiers change)
var _cached_stats: Dictionary = {}
var _cache_dirty: bool = true

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_initialize_modifiers()
	_apply_meta_progression()
	_recalculate_all_stats()


func _initialize_modifiers() -> void:
	for stat_name in base_stats:
		modifiers[stat_name] = {}


func _apply_meta_progression() -> void:
	# Apply permanent upgrades from SaveManager
	var entity := get_parent()
	if entity == null or not entity.is_in_group("player"):
		return

	# Max HP bonus
	var hp_bonus := SaveManager.get_upgrade_bonus("max_hp")
	if hp_bonus > 0:
		add_modifier(STAT_MAX_HEALTH, "meta_hp", "add", hp_bonus)

	# Damage bonus
	var damage_bonus := SaveManager.get_upgrade_bonus("damage")
	if damage_bonus > 0:
		add_modifier(STAT_DAMAGE, "meta_damage", "mult", 1.0 + damage_bonus)

	# Move speed bonus
	var speed_bonus := SaveManager.get_upgrade_bonus("move_speed")
	if speed_bonus > 0:
		add_modifier(STAT_MOVE_SPEED, "meta_speed", "mult", 1.0 + speed_bonus)

	# XP gain bonus
	var xp_bonus := SaveManager.get_upgrade_bonus("xp_gain")
	if xp_bonus > 0:
		add_modifier(STAT_XP_GAIN, "meta_xp", "mult", 1.0 + xp_bonus)

	# Luck bonus
	var luck_bonus := SaveManager.get_upgrade_bonus("luck")
	if luck_bonus > 0:
		add_modifier(STAT_LUCK, "meta_luck", "mult", 1.0 + luck_bonus)

# =============================================================================
# STAT ACCESS
# =============================================================================

func get_stat(stat_name: String) -> float:
	if _cache_dirty:
		_recalculate_all_stats()

	return _cached_stats.get(stat_name, base_stats.get(stat_name, 0.0))


func get_base_stat(stat_name: String) -> float:
	return base_stats.get(stat_name, 0.0)


func set_base_stat(stat_name: String, value: float) -> void:
	var old_value := get_stat(stat_name)
	base_stats[stat_name] = value
	_cache_dirty = true

	if stat_name not in modifiers:
		modifiers[stat_name] = {}

	var new_value := get_stat(stat_name)
	if old_value != new_value:
		stat_changed.emit(stat_name, old_value, new_value)

# =============================================================================
# MODIFIER MANAGEMENT
# =============================================================================

func add_modifier(stat_name: String, modifier_id: String, modifier_type: String, value: float) -> void:
	## modifier_type: "add" for additive, "mult" for multiplicative

	if stat_name not in modifiers:
		modifiers[stat_name] = {}

	var old_value := get_stat(stat_name)

	modifiers[stat_name][modifier_id] = {
		"type": modifier_type,
		"value": value
	}

	_cache_dirty = true
	modifier_added.emit(stat_name, modifier_id)

	var new_value := get_stat(stat_name)
	if old_value != new_value:
		stat_changed.emit(stat_name, old_value, new_value)


func remove_modifier(stat_name: String, modifier_id: String) -> void:
	if stat_name not in modifiers:
		return

	if modifier_id not in modifiers[stat_name]:
		return

	var old_value := get_stat(stat_name)

	modifiers[stat_name].erase(modifier_id)
	_cache_dirty = true
	modifier_removed.emit(stat_name, modifier_id)

	var new_value := get_stat(stat_name)
	if old_value != new_value:
		stat_changed.emit(stat_name, old_value, new_value)


func has_modifier(stat_name: String, modifier_id: String) -> bool:
	if stat_name not in modifiers:
		return false
	return modifier_id in modifiers[stat_name]


func clear_modifiers(stat_name: String) -> void:
	if stat_name not in modifiers:
		return

	var old_value := get_stat(stat_name)
	modifiers[stat_name].clear()
	_cache_dirty = true

	var new_value := get_stat(stat_name)
	if old_value != new_value:
		stat_changed.emit(stat_name, old_value, new_value)


func clear_all_modifiers() -> void:
	for stat_name in modifiers:
		modifiers[stat_name].clear()
	_cache_dirty = true
	_recalculate_all_stats()

# =============================================================================
# STAT CALCULATION
# =============================================================================

func _recalculate_all_stats() -> void:
	for stat_name in base_stats:
		_cached_stats[stat_name] = _calculate_stat(stat_name)
	_cache_dirty = false


func _calculate_stat(stat_name: String) -> float:
	var base: float = base_stats.get(stat_name, 0.0)
	var additive: float = 0.0
	var multiplicative: float = 1.0

	if stat_name in modifiers:
		for modifier_id in modifiers[stat_name]:
			var mod: Dictionary = modifiers[stat_name][modifier_id]
			match mod.type:
				"add":
					additive += mod.value
				"mult":
					multiplicative *= mod.value

	return (base + additive) * multiplicative

# =============================================================================
# CONVENIENCE METHODS
# =============================================================================

func get_max_health() -> int:
	return int(get_stat(STAT_MAX_HEALTH))


func get_move_speed() -> float:
	return get_stat(STAT_MOVE_SPEED)


func get_damage() -> float:
	return get_stat(STAT_DAMAGE)


func get_attack_speed() -> float:
	return get_stat(STAT_ATTACK_SPEED)


func get_crit_chance() -> float:
	return get_stat(STAT_CRIT_CHANCE)


func get_crit_damage() -> float:
	return get_stat(STAT_CRIT_DAMAGE)


func roll_crit() -> bool:
	return randf() < get_crit_chance()


func calculate_damage(base_damage: float) -> int:
	var damage := base_damage * get_stat(STAT_DAMAGE)
	if roll_crit():
		damage *= get_crit_damage()
	return int(damage)


func get_cooldown_multiplier() -> float:
	# CDR is stored as reduction, so we convert to multiplier
	return maxf(0.1, 1.0 - get_stat(STAT_COOLDOWN_REDUCTION))


func get_xp_multiplier() -> float:
	return get_stat(STAT_XP_GAIN)


func get_gold_multiplier() -> float:
	return get_stat(STAT_GOLD_GAIN)


func get_pickup_radius() -> float:
	return get_stat(STAT_PICKUP_RADIUS)

# =============================================================================
# SERIALIZATION
# =============================================================================

func get_stats_dict() -> Dictionary:
	if _cache_dirty:
		_recalculate_all_stats()
	return _cached_stats.duplicate()


func get_modifiers_dict() -> Dictionary:
	return modifiers.duplicate(true)
