## ItemData - Resource defining a passive item
## Create .tres files in data/items/ for each item
class_name ItemData
extends Resource

# =============================================================================
# ENUMS
# =============================================================================

enum ItemRarity {
	COMMON,
	UNCOMMON,
	RARE,
	LEGENDARY
}

enum ItemCategory {
	STAT_BOOST,    # Simple stat increases
	SPECIAL,       # Unique effects
	EVOLUTION,     # Required for weapon evolution
	CONSUMABLE     # One-time use (like food)
}

# =============================================================================
# BASIC INFO
# =============================================================================

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export var rarity: ItemRarity = ItemRarity.COMMON
@export var category: ItemCategory = ItemCategory.STAT_BOOST

# =============================================================================
# VISUALS
# =============================================================================

@export_group("Visuals")
@export var icon: Texture2D = null
@export var pickup_effect: PackedScene = null

# Rarity colors
const RARITY_COLORS: Dictionary = {
	ItemRarity.COMMON: Color.WHITE,
	ItemRarity.UNCOMMON: Color.GREEN,
	ItemRarity.RARE: Color.BLUE,
	ItemRarity.LEGENDARY: Color.GOLD
}

# =============================================================================
# STAT MODIFIERS
# =============================================================================

@export_group("Stat Modifiers")
## Dictionary format: {"stat_name": {"type": "add/mult", "value": float}}
@export var stat_modifiers: Dictionary = {}

# Common stat modifier shortcuts
@export var max_health_bonus: float = 0.0  # Flat bonus
@export var max_health_mult: float = 1.0   # Multiplier (1.0 = no change)
@export var damage_mult: float = 1.0
@export var move_speed_mult: float = 1.0
@export var cooldown_reduction: float = 0.0  # 0.0-1.0 percentage
@export var xp_gain_mult: float = 1.0
@export var pickup_radius_bonus: float = 0.0
@export var luck_mult: float = 1.0
@export var armor_bonus: float = 0.0
@export var crit_chance_bonus: float = 0.0
@export var crit_damage_mult: float = 1.0

# =============================================================================
# LEVELING
# =============================================================================

@export_group("Leveling")
@export var max_level: int = 5
@export var can_stack: bool = true  # Can pick up multiple

# Per-level scaling (multiplies the base effect)
@export var effect_per_level: float = 1.0  # Additional % of base per level

# =============================================================================
# SPECIAL EFFECTS
# =============================================================================

@export_group("Special Effects")
@export var has_special_effect: bool = false
@export var special_effect_id: String = ""  # Links to code-defined effect

# Common special effects
@export var lifesteal_percent: float = 0.0
@export var thorns_percent: float = 0.0  # Reflect damage
@export var regen_per_second: float = 0.0
@export var gold_gain_mult: float = 1.0
@export var revival_count: int = 0

# =============================================================================
# EVOLUTION PAIRING
# =============================================================================

@export_group("Evolution")
@export var evolves_weapon_id: String = ""  # Which weapon this item evolves

# =============================================================================
# AUDIO
# =============================================================================

@export_group("Audio")
@export var pickup_sound: AudioStream = null
@export var level_up_sound: AudioStream = null

# =============================================================================
# METHODS
# =============================================================================

func get_all_modifiers() -> Dictionary:
	## Returns complete dictionary of all stat modifiers
	var mods := stat_modifiers.duplicate(true)

	# Add shortcut modifiers
	if max_health_bonus != 0.0:
		mods["max_health_add"] = {"type": "add", "value": max_health_bonus}
	if max_health_mult != 1.0:
		mods["max_health"] = {"type": "mult", "value": max_health_mult}
	if damage_mult != 1.0:
		mods["damage"] = {"type": "mult", "value": damage_mult}
	if move_speed_mult != 1.0:
		mods["move_speed"] = {"type": "mult", "value": move_speed_mult}
	if cooldown_reduction != 0.0:
		mods["cooldown_reduction"] = {"type": "add", "value": cooldown_reduction}
	if xp_gain_mult != 1.0:
		mods["xp_gain"] = {"type": "mult", "value": xp_gain_mult}
	if pickup_radius_bonus != 0.0:
		mods["pickup_radius"] = {"type": "add", "value": pickup_radius_bonus}
	if luck_mult != 1.0:
		mods["luck"] = {"type": "mult", "value": luck_mult}
	if armor_bonus != 0.0:
		mods["armor"] = {"type": "add", "value": armor_bonus}
	if crit_chance_bonus != 0.0:
		mods["crit_chance"] = {"type": "add", "value": crit_chance_bonus}
	if crit_damage_mult != 1.0:
		mods["crit_damage"] = {"type": "mult", "value": crit_damage_mult}
	if lifesteal_percent != 0.0:
		mods["lifesteal"] = {"type": "add", "value": lifesteal_percent}
	if gold_gain_mult != 1.0:
		mods["gold_gain"] = {"type": "mult", "value": gold_gain_mult}

	return mods


func get_modifiers_at_level(level: int) -> Dictionary:
	## Returns modifiers scaled for current item level
	var base_mods := get_all_modifiers()
	var level_mult := 1.0 + (effect_per_level * (level - 1))

	for stat_name in base_mods:
		var mod: Dictionary = base_mods[stat_name]
		if mod.type == "add":
			mod.value *= level_mult
		elif mod.type == "mult":
			# For multipliers, scale the bonus portion
			var bonus := mod.value - 1.0
			mod.value = 1.0 + (bonus * level_mult)

	return base_mods


func get_description_at_level(level: int) -> String:
	## Returns formatted description with current values
	var mods := get_modifiers_at_level(level)
	var desc := ""

	for stat_name in mods:
		var mod: Dictionary = mods[stat_name]
		var stat_display := stat_name.replace("_", " ").capitalize()

		if mod.type == "add":
			var sign := "+" if mod.value >= 0 else ""
			desc += "%s%d %s\n" % [sign, int(mod.value), stat_display]
		else:
			var percent := (mod.value - 1.0) * 100
			var sign := "+" if percent >= 0 else ""
			desc += "%s%d%% %s\n" % [sign, int(percent), stat_display]

	# Add special effects
	if regen_per_second > 0:
		desc += "+%.1f HP/sec\n" % regen_per_second
	if thorns_percent > 0:
		desc += "Reflect %d%% damage\n" % int(thorns_percent * 100)
	if revival_count > 0:
		desc += "+%d Revival\n" % revival_count

	return desc.strip_edges()


func get_rarity_name() -> String:
	match rarity:
		ItemRarity.COMMON: return "Common"
		ItemRarity.UNCOMMON: return "Uncommon"
		ItemRarity.RARE: return "Rare"
		ItemRarity.LEGENDARY: return "Legendary"
	return "Unknown"


func get_rarity_color() -> Color:
	return RARITY_COLORS.get(rarity, Color.WHITE)


func get_category_name() -> String:
	match category:
		ItemCategory.STAT_BOOST: return "Stat Boost"
		ItemCategory.SPECIAL: return "Special"
		ItemCategory.EVOLUTION: return "Evolution"
		ItemCategory.CONSUMABLE: return "Consumable"
	return "Unknown"


func can_level_up(current_level: int) -> bool:
	return can_stack and current_level < max_level
