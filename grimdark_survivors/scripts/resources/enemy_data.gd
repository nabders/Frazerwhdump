## EnemyData - Resource defining an enemy type
## Create .tres files in data/enemies/ for each enemy type
class_name EnemyData
extends Resource

# =============================================================================
# ENUMS
# =============================================================================

enum EnemyCategory {
	COMMON,      # Basic swarmers
	UNCOMMON,    # Special abilities
	ELITE,       # Stronger variants
	BOSS         # Stage bosses
}

enum MovementPattern {
	CHASE,        # Walks directly toward player
	WANDER,       # Random movement
	CHARGE,       # Pauses then dashes
	CIRCLE,       # Circles around player
	STATIONARY,   # Doesn't move
	TELEPORT,     # Blinks around
	FLEE          # Runs away when close
}

enum AttackPattern {
	CONTACT,      # Damages on touch
	MELEE,        # Stops to attack
	RANGED,       # Fires projectiles
	AOE,          # Area of effect
	SUMMON,       # Spawns other enemies
	EXPLOSION     # Explodes on death
}

# =============================================================================
# BASIC INFO
# =============================================================================

@export var id: String = ""
@export var display_name: String = ""
@export var category: EnemyCategory = EnemyCategory.COMMON
@export_multiline var death_quote: String = ""  # For bosses

# =============================================================================
# VISUALS
# =============================================================================

@export_group("Visuals")
@export var sprite_sheet: Texture2D = null
@export var sprite_frames: SpriteFrames = null
@export var scale: float = 1.0
@export var shadow_scale: float = 1.0
@export var hit_flash_color: Color = Color.WHITE

# =============================================================================
# STATS
# =============================================================================

@export_group("Stats")
@export var max_health: int = 10
@export var damage: int = 5  # Contact/attack damage
@export var move_speed: float = 80.0
@export var armor: float = 0.0  # Flat damage reduction
@export var knockback_resistance: float = 0.0  # 0.0-1.0

# XP and rewards
@export var xp_value: int = 1
@export var gold_drop_chance: float = 0.1
@export var gold_amount: int = 1

# =============================================================================
# BEHAVIOR
# =============================================================================

@export_group("Behavior")
@export var movement_pattern: MovementPattern = MovementPattern.CHASE
@export var attack_pattern: AttackPattern = AttackPattern.CONTACT

# Detection and aggro
@export var detection_range: float = 500.0
@export var attack_range: float = 30.0  # For melee attackers
@export var de_aggro_range: float = 800.0

# Attack timing
@export var attack_cooldown: float = 1.0
@export var attack_windup: float = 0.3  # Telegraph time before attack

# Special behaviors
@export var explodes_on_death: bool = false
@export var splits_on_death: bool = false
@export var split_enemy_id: String = ""
@export var split_count: int = 2

# =============================================================================
# CHARGE PATTERN (if movement_pattern == CHARGE)
# =============================================================================

@export_group("Charge Behavior")
@export var charge_speed_multiplier: float = 3.0
@export var charge_duration: float = 0.5
@export var charge_cooldown: float = 2.0
@export var charge_telegraph_time: float = 0.5

# =============================================================================
# RANGED PATTERN (if attack_pattern == RANGED)
# =============================================================================

@export_group("Ranged Attack")
@export var projectile_scene: PackedScene = null
@export var projectile_speed: float = 200.0
@export var projectile_count: int = 1
@export var projectile_spread: float = 0.0  # Degrees

# =============================================================================
# SUMMON PATTERN (if attack_pattern == SUMMON)
# =============================================================================

@export_group("Summon Behavior")
@export var summon_enemy_id: String = ""
@export var summon_count: int = 2
@export var summon_cooldown: float = 5.0

# =============================================================================
# BOSS SPECIFIC
# =============================================================================

@export_group("Boss")
@export var is_boss: bool = false
@export var boss_phases: int = 1
@export var phase_health_thresholds: Array[float] = []  # HP % to change phase
@export var boss_spawn_minute: int = 5

# =============================================================================
# AUDIO
# =============================================================================

@export_group("Audio")
@export var spawn_sound: AudioStream = null
@export var attack_sound: AudioStream = null
@export var hurt_sounds: Array[AudioStream] = []
@export var death_sound: AudioStream = null

# =============================================================================
# SCALING
# =============================================================================

## Stats scale based on game time - this defines the multipliers
@export_group("Time Scaling")
@export var health_scale_per_minute: float = 0.1  # +10% per minute
@export var damage_scale_per_minute: float = 0.05  # +5% per minute
@export var speed_scale_per_minute: float = 0.02  # +2% per minute
@export var max_scale_minute: int = 20  # Stop scaling after this

# =============================================================================
# METHODS
# =============================================================================

func get_scaled_stats(minute: int) -> Dictionary:
	## Returns stats scaled for current game time
	var scale_minute := mini(minute, max_scale_minute)

	return {
		"max_health": int(max_health * (1.0 + health_scale_per_minute * scale_minute)),
		"damage": int(damage * (1.0 + damage_scale_per_minute * scale_minute)),
		"move_speed": move_speed * (1.0 + speed_scale_per_minute * scale_minute),
		"armor": armor,
		"knockback_resistance": knockback_resistance,
		"xp_value": xp_value
	}


func get_health_at_minute(minute: int) -> int:
	var scale_minute := mini(minute, max_scale_minute)
	return int(max_health * (1.0 + health_scale_per_minute * scale_minute))


func get_damage_at_minute(minute: int) -> int:
	var scale_minute := mini(minute, max_scale_minute)
	return int(damage * (1.0 + damage_scale_per_minute * scale_minute))


func should_drop_gold() -> bool:
	return randf() < gold_drop_chance


func get_category_name() -> String:
	match category:
		EnemyCategory.COMMON: return "Common"
		EnemyCategory.UNCOMMON: return "Uncommon"
		EnemyCategory.ELITE: return "Elite"
		EnemyCategory.BOSS: return "Boss"
	return "Unknown"


func get_current_phase(health_percent: float) -> int:
	## For bosses, returns current phase based on HP
	if not is_boss or phase_health_thresholds.is_empty():
		return 1

	var phase := 1
	for threshold in phase_health_thresholds:
		if health_percent <= threshold:
			phase += 1
		else:
			break

	return mini(phase, boss_phases)
