## WeaponData - Resource defining a weapon
## Create .tres files in data/weapons/ for each weapon
class_name WeaponData
extends Resource

# =============================================================================
# ENUMS
# =============================================================================

enum WeaponCategory {
	MELEE,
	PROJECTILE,
	ORBITAL,
	AREA,
	SUMMON,
	PASSIVE
}

enum DamageType {
	PHYSICAL,
	FIRE,
	ICE,
	LIGHTNING,
	POISON,
	HOLY
}

# =============================================================================
# BASIC INFO
# =============================================================================

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var category: WeaponCategory = WeaponCategory.MELEE
@export var damage_type: DamageType = DamageType.PHYSICAL

# =============================================================================
# VISUALS
# =============================================================================

@export_group("Visuals")
@export var icon: Texture2D = null
@export var projectile_scene: PackedScene = null
@export var effect_scene: PackedScene = null
@export var animation_name: String = ""

# =============================================================================
# BASE STATS
# =============================================================================

@export_group("Base Stats")
@export var base_damage: int = 10
@export var base_cooldown: float = 1.0  # Seconds between attacks
@export var base_area: float = 1.0  # Area multiplier
@export var base_speed: float = 1.0  # Projectile/attack speed multiplier
@export var base_duration: float = 1.0  # Duration multiplier for effects
@export var base_knockback: float = 50.0

# Projectile/summon count
@export var base_amount: int = 1  # Number of projectiles/summons/orbits

# Range and targeting
@export var base_range: float = 100.0  # Attack range
@export var pierce_count: int = 1  # How many enemies projectiles pass through
@export var can_crit: bool = true

# =============================================================================
# LEVEL SCALING
# =============================================================================

@export_group("Level Scaling")
@export var max_level: int = 8

# Per-level increases (additive per level)
@export var damage_per_level: int = 5
@export var cooldown_reduction_per_level: float = 0.05  # Percentage
@export var area_per_level: float = 0.1  # Percentage
@export var amount_per_level: int = 0  # Additional projectiles
@export var pierce_per_level: int = 0
@export var duration_per_level: float = 0.0

# Specific level bonuses (level: bonus_description)
@export var level_bonuses: Dictionary = {}
# Example: {3: "+1 Projectile", 5: "Pass through walls", 8: "Double damage"}

# =============================================================================
# EVOLUTION
# =============================================================================

@export_group("Evolution")
@export var can_evolve: bool = false
@export var evolution_item_id: String = ""  # Item needed to evolve
@export var evolved_weapon: Resource = null  # WeaponData of evolved form

# =============================================================================
# BEHAVIOR
# =============================================================================

@export_group("Behavior")
@export var auto_aim: bool = true  # Automatically targets nearest enemy
@export var requires_target: bool = false  # Won't fire without enemy in range
@export var hits_multiple: bool = false  # Hits all enemies in area
@export var rotates_with_movement: bool = false  # For orbital weapons
@export var follows_player: bool = true  # Summons follow player

# =============================================================================
# AUDIO
# =============================================================================

@export_group("Audio")
@export var fire_sound: AudioStream = null
@export var hit_sound: AudioStream = null
@export var level_up_sound: AudioStream = null

# =============================================================================
# METHODS
# =============================================================================

func get_stats_at_level(level: int) -> Dictionary:
	## Returns all stats for this weapon at specified level
	var clamped_level := clampi(level, 1, max_level)
	var levels_gained := clamped_level - 1

	return {
		"damage": base_damage + (damage_per_level * levels_gained),
		"cooldown": base_cooldown * (1.0 - (cooldown_reduction_per_level * levels_gained)),
		"area": base_area * (1.0 + (area_per_level * levels_gained)),
		"speed": base_speed,
		"duration": base_duration + (duration_per_level * levels_gained),
		"knockback": base_knockback,
		"amount": base_amount + (amount_per_level * levels_gained),
		"range": base_range,
		"pierce": pierce_count + (pierce_per_level * levels_gained)
	}


func get_damage_at_level(level: int) -> int:
	var clamped_level := clampi(level, 1, max_level)
	return base_damage + (damage_per_level * (clamped_level - 1))


func get_cooldown_at_level(level: int) -> float:
	var clamped_level := clampi(level, 1, max_level)
	var reduction := cooldown_reduction_per_level * (clamped_level - 1)
	return base_cooldown * maxf(0.1, 1.0 - reduction)


func get_amount_at_level(level: int) -> int:
	var clamped_level := clampi(level, 1, max_level)
	return base_amount + (amount_per_level * (clamped_level - 1))


func is_max_level(current_level: int) -> bool:
	return current_level >= max_level


func can_evolve_at_level(current_level: int, has_required_item: bool) -> bool:
	return can_evolve and is_max_level(current_level) and has_required_item


func get_level_up_description(from_level: int) -> String:
	## Returns description of what improves at next level
	var next_level := from_level + 1
	if next_level > max_level:
		return "MAX LEVEL"

	var desc := ""

	if damage_per_level > 0:
		desc += "+%d Damage\n" % damage_per_level

	if cooldown_reduction_per_level > 0:
		desc += "-%d%% Cooldown\n" % int(cooldown_reduction_per_level * 100)

	if area_per_level > 0:
		desc += "+%d%% Area\n" % int(area_per_level * 100)

	if amount_per_level > 0 and next_level > 1:
		# Check if this level gives amount bonus
		var amount_at_current := get_amount_at_level(from_level)
		var amount_at_next := get_amount_at_level(next_level)
		if amount_at_next > amount_at_current:
			desc += "+%d Projectile\n" % (amount_at_next - amount_at_current)

	# Check for special level bonus
	if next_level in level_bonuses:
		desc += level_bonuses[next_level] + "\n"

	return desc.strip_edges()


func get_category_name() -> String:
	match category:
		WeaponCategory.MELEE: return "Melee"
		WeaponCategory.PROJECTILE: return "Projectile"
		WeaponCategory.ORBITAL: return "Orbital"
		WeaponCategory.AREA: return "Area"
		WeaponCategory.SUMMON: return "Summon"
		WeaponCategory.PASSIVE: return "Passive"
	return "Unknown"


func get_damage_type_name() -> String:
	match damage_type:
		DamageType.PHYSICAL: return "Physical"
		DamageType.FIRE: return "Fire"
		DamageType.ICE: return "Ice"
		DamageType.LIGHTNING: return "Lightning"
		DamageType.POISON: return "Poison"
		DamageType.HOLY: return "Holy"
	return "Unknown"
