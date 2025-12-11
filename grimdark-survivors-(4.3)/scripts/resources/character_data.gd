## CharacterData - Resource defining a playable character
## Create .tres files in data/characters/ for each character
class_name CharacterData
extends Resource

# =============================================================================
# BASIC INFO
# =============================================================================

@export var id: String = ""
@export var display_name: String = ""
@export var class_name_display: String = ""  # e.g., "Knight", "Mage", "Barbarian"
@export_multiline var description: String = ""
@export_multiline var flavor_text: String = ""  # Humorous description

# =============================================================================
# VISUALS
# =============================================================================

@export var portrait: Texture2D = null
@export var sprite_sheet: Texture2D = null
@export var sprite_frames: SpriteFrames = null
@export var color_palette: Array[Color] = []

# =============================================================================
# BASE STATS
# =============================================================================

@export_group("Base Stats")
@export var base_max_health: int = 100
@export var base_move_speed: float = 200.0
@export var base_damage: float = 1.0  # Multiplier
@export var base_armor: float = 0.0
@export var base_pickup_radius: float = 50.0

# =============================================================================
# STARTING EQUIPMENT
# =============================================================================

@export_group("Starting Equipment")
@export var starting_weapon: Resource = null  # WeaponData
@export var starting_items: Array[Resource] = []  # Array of ItemData

# =============================================================================
# PASSIVE ABILITY
# =============================================================================

@export_group("Passive Ability")
@export var passive_name: String = ""
@export_multiline var passive_description: String = ""
@export var passive_stat_modifiers: Dictionary = {}
# Example: {"max_health": {"type": "mult", "value": 1.1}} for +10% HP

# Special passive flags
@export var has_special_passive: bool = false
@export var special_passive_id: String = ""  # For unique abilities requiring code

# =============================================================================
# UNLOCK CONDITIONS
# =============================================================================

@export_group("Unlock")
@export var is_starting_character: bool = false
@export var unlock_condition: String = ""  # Human readable
@export var unlock_stat: String = ""  # Stat to check (from SaveManager.statistics)
@export var unlock_threshold: int = 0  # Value needed

# =============================================================================
# AUDIO
# =============================================================================

@export_group("Audio")
@export var select_sound: AudioStream = null
@export var hurt_sounds: Array[AudioStream] = []
@export var death_sound: AudioStream = null

# =============================================================================
# METHODS
# =============================================================================

func get_stat_modifiers() -> Dictionary:
	## Returns all stat modifiers for this character
	var mods := passive_stat_modifiers.duplicate(true)

	# Add base stat differences from default
	if base_max_health != 100:
		mods["max_health"] = {"type": "add", "value": base_max_health - 100}

	if base_move_speed != 200.0:
		mods["move_speed"] = {"type": "add", "value": base_move_speed - 200.0}

	if base_damage != 1.0:
		mods["damage"] = {"type": "mult", "value": base_damage}

	if base_armor != 0.0:
		mods["armor"] = {"type": "add", "value": base_armor}

	if base_pickup_radius != 50.0:
		mods["pickup_radius"] = {"type": "add", "value": base_pickup_radius - 50.0}

	return mods


func is_unlocked() -> bool:
	if is_starting_character:
		return true

	return SaveManager.is_character_unlocked(id)


func check_unlock_condition() -> bool:
	## Check if unlock conditions are met
	if is_starting_character:
		return true

	if unlock_stat.is_empty():
		return false

	var current_value: int = SaveManager.get_statistic(unlock_stat)
	return current_value >= unlock_threshold


func get_unlock_progress() -> float:
	## Returns 0.0 to 1.0 progress toward unlock
	if is_unlocked():
		return 1.0

	if unlock_stat.is_empty() or unlock_threshold <= 0:
		return 0.0

	var current_value: int = SaveManager.get_statistic(unlock_stat)
	return clampf(float(current_value) / float(unlock_threshold), 0.0, 1.0)
