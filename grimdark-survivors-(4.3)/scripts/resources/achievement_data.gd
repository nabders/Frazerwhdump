## AchievementData - Resource defining an achievement
## Create .tres files in data/achievements/ for each achievement
class_name AchievementData
extends Resource

# =============================================================================
# ENUMS
# =============================================================================

enum AchievementCategory {
	COMBAT,       # Killing, damage, etc.
	SURVIVAL,     # Time survived, runs completed
	COLLECTION,   # Items, weapons, pickups
	PROGRESSION,  # Unlocks, upgrades
	SECRET        # Hidden achievements
}

enum AchievementType {
	STAT_THRESHOLD,  # Reach a certain stat value
	SINGLE_RUN,      # Do something in one run
	CUMULATIVE,      # Total across all runs
	SPECIAL          # Code-defined special condition
}

# =============================================================================
# BASIC INFO
# =============================================================================

@export var id: String = ""
@export var display_name: String = ""
@export_multiline var description: String = ""
@export_multiline var flavor_text: String = ""  # Humorous unlock message
@export var category: AchievementCategory = AchievementCategory.COMBAT
@export var achievement_type: AchievementType = AchievementType.CUMULATIVE

# =============================================================================
# VISUALS
# =============================================================================

@export_group("Visuals")
@export var icon: Texture2D = null
@export var icon_locked: Texture2D = null  # Shown before unlocking
@export var is_hidden: bool = false  # Don't show until unlocked

# =============================================================================
# UNLOCK CONDITIONS
# =============================================================================

@export_group("Unlock Conditions")
@export var stat_to_track: String = ""  # Stat name from SaveManager
@export var required_value: int = 0
@export var required_character: String = ""  # Must be using this character
@export var required_weapon: String = ""  # Must have this weapon
@export var required_item: String = ""  # Must have this item

# For single-run achievements
@export var run_stat: String = ""  # Stat tracked per run
@export var run_value: int = 0

# For special achievements
@export var special_condition_id: String = ""

# =============================================================================
# REWARDS
# =============================================================================

@export_group("Rewards")
@export var gold_reward: int = 0
@export var unlocks_character: String = ""  # Character ID to unlock
@export var unlocks_weapon: String = ""  # Weapon ID to unlock
@export var unlocks_item: String = ""  # Item ID to unlock

# =============================================================================
# AUDIO
# =============================================================================

@export_group("Audio")
@export var unlock_sound: AudioStream = null

# =============================================================================
# METHODS
# =============================================================================

func is_unlocked() -> bool:
	return SaveManager.is_achievement_unlocked(id)


func check_unlock() -> bool:
	## Check if unlock conditions are met
	if is_unlocked():
		return true

	match achievement_type:
		AchievementType.STAT_THRESHOLD, AchievementType.CUMULATIVE:
			return _check_stat_condition()
		AchievementType.SINGLE_RUN:
			return _check_single_run_condition()
		AchievementType.SPECIAL:
			return _check_special_condition()

	return false


func _check_stat_condition() -> bool:
	if stat_to_track.is_empty():
		return false

	var current_value: int = SaveManager.get_statistic(stat_to_track)
	return current_value >= required_value


func _check_single_run_condition() -> bool:
	# Single run achievements are checked at end of run
	# This returns false by default - actual check happens in GameManager
	return false


func _check_special_condition() -> bool:
	# Special conditions are checked by code
	# Return false by default
	return false


func unlock() -> void:
	## Unlock this achievement and grant rewards
	if is_unlocked():
		return

	SaveManager.unlock_achievement(id)

	# Grant rewards
	if gold_reward > 0:
		SaveManager.add_gold(gold_reward)

	if not unlocks_character.is_empty():
		SaveManager.unlock_character(unlocks_character)

	# Weapon and item unlocks would be handled similarly
	# when those systems are implemented

	# Play sound
	if unlock_sound:
		EventBus.sfx_requested.emit("achievement")

	# Show notification
	EventBus.show_notification.emit("Achievement Unlocked: %s" % display_name, 3.0)


func get_progress() -> float:
	## Returns progress 0.0 to 1.0
	if is_unlocked():
		return 1.0

	if stat_to_track.is_empty() or required_value <= 0:
		return 0.0

	var current_value: int = SaveManager.get_statistic(stat_to_track)
	return clampf(float(current_value) / float(required_value), 0.0, 1.0)


func get_progress_text() -> String:
	## Returns "current / required" or "Unlocked"
	if is_unlocked():
		return "Unlocked"

	if stat_to_track.is_empty():
		if is_hidden:
			return "???"
		return "Special"

	var current_value: int = SaveManager.get_statistic(stat_to_track)
	return "%d / %d" % [current_value, required_value]


func get_category_name() -> String:
	match category:
		AchievementCategory.COMBAT: return "Combat"
		AchievementCategory.SURVIVAL: return "Survival"
		AchievementCategory.COLLECTION: return "Collection"
		AchievementCategory.PROGRESSION: return "Progression"
		AchievementCategory.SECRET: return "Secret"
	return "Unknown"


func get_display_description() -> String:
	## Returns description, or ??? if hidden and not unlocked
	if is_hidden and not is_unlocked():
		return "???"
	return description
