## SaveManager - Handles persistent data, unlocks, and save/load operations
## Manages meta progression, achievements, and player statistics
extends Node

# =============================================================================
# CONSTANTS
# =============================================================================

const SAVE_FILE_PATH: String = "user://grimdark_save.dat"
const SAVE_VERSION: int = 1
const ENCRYPTION_KEY: String = "grimdark_survivors_2024"

# =============================================================================
# SAVE DATA STRUCTURE
# =============================================================================

var save_data: Dictionary = {
	"version": SAVE_VERSION,
	"meta_gold": 0,
	"total_gold_earned": 0,
	"unlocked_characters": ["knight", "mage", "barbarian"],  # Starting characters
	"unlocked_achievements": [],
	"upgrades": {
		"max_hp": 0,
		"damage": 0,
		"move_speed": 0,
		"xp_gain": 0,
		"starting_gold": 0,
		"luck": 0,
		"revivals": 0
	},
	"statistics": {
		"total_runs": 0,
		"total_kills": 0,
		"total_deaths": 0,
		"total_victories": 0,
		"total_time_played": 0.0,
		"highest_level": 0,
		"longest_run": 0.0,
		"total_damage_dealt": 0,
		"boss_kills": 0,
		"rats_killed": 0,  # For Lord Rattington unlock
		"chests_opened": 0,
		"food_collected": 0
	},
	"settings": {
		"master_volume": 1.0,
		"music_volume": 0.8,
		"sfx_volume": 1.0,
		"screen_shake": true,
		"damage_numbers": true
	}
}

# =============================================================================
# UPGRADE COSTS
# =============================================================================

const UPGRADE_BASE_COSTS: Dictionary = {
	"max_hp": 100,
	"damage": 150,
	"move_speed": 200,
	"xp_gain": 125,
	"starting_gold": 75,
	"luck": 175,
	"revivals": 500
}

const UPGRADE_COST_SCALING: float = 1.5
const MAX_REVIVAL_LEVEL: int = 3

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	load_game()
	print("[SaveManager] Initialized - Gold: %d" % save_data.meta_gold)


func _notification(what: int) -> void:
	# Auto-save when game is closing
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()

# =============================================================================
# SAVE/LOAD
# =============================================================================

func save_game() -> void:
	var file := FileAccess.open_encrypted_with_pass(SAVE_FILE_PATH, FileAccess.WRITE, ENCRYPTION_KEY)

	if file == null:
		# Fallback to unencrypted for debugging
		file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
		if file == null:
			push_error("[SaveManager] Failed to open save file for writing")
			return

	var json_string := JSON.stringify(save_data)
	file.store_string(json_string)
	file.close()
	print("[SaveManager] Game saved successfully")


func load_game() -> void:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("[SaveManager] No save file found, using defaults")
		return

	var file := FileAccess.open_encrypted_with_pass(SAVE_FILE_PATH, FileAccess.READ, ENCRYPTION_KEY)

	if file == null:
		# Try unencrypted fallback
		file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
		if file == null:
			push_error("[SaveManager] Failed to open save file for reading")
			return

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var error := json.parse(json_string)

	if error != OK:
		push_error("[SaveManager] Failed to parse save file")
		return

	var loaded_data: Dictionary = json.data

	# Version migration if needed
	if loaded_data.get("version", 0) < SAVE_VERSION:
		loaded_data = _migrate_save_data(loaded_data)

	# Merge loaded data with defaults (in case of new fields)
	_merge_save_data(loaded_data)
	print("[SaveManager] Game loaded successfully")


func _migrate_save_data(old_data: Dictionary) -> Dictionary:
	# Handle save file version migrations here
	print("[SaveManager] Migrating save from version %d to %d" % [old_data.get("version", 0), SAVE_VERSION])
	old_data["version"] = SAVE_VERSION
	return old_data


func _merge_save_data(loaded_data: Dictionary) -> void:
	# Recursively merge loaded data with defaults
	for key in save_data.keys():
		if key in loaded_data:
			if save_data[key] is Dictionary and loaded_data[key] is Dictionary:
				for sub_key in save_data[key].keys():
					if sub_key in loaded_data[key]:
						save_data[key][sub_key] = loaded_data[key][sub_key]
			else:
				save_data[key] = loaded_data[key]


func reset_save() -> void:
	# Reset to defaults
	save_data = {
		"version": SAVE_VERSION,
		"meta_gold": 0,
		"total_gold_earned": 0,
		"unlocked_characters": ["knight", "mage", "barbarian"],
		"unlocked_achievements": [],
		"upgrades": {
			"max_hp": 0,
			"damage": 0,
			"move_speed": 0,
			"xp_gain": 0,
			"starting_gold": 0,
			"luck": 0,
			"revivals": 0
		},
		"statistics": {
			"total_runs": 0,
			"total_kills": 0,
			"total_deaths": 0,
			"total_victories": 0,
			"total_time_played": 0.0,
			"highest_level": 0,
			"longest_run": 0.0,
			"total_damage_dealt": 0,
			"boss_kills": 0,
			"rats_killed": 0,
			"chests_opened": 0,
			"food_collected": 0
		},
		"settings": {
			"master_volume": 1.0,
			"music_volume": 0.8,
			"sfx_volume": 1.0,
			"screen_shake": true,
			"damage_numbers": true
		}
	}
	save_game()
	print("[SaveManager] Save data reset")

# =============================================================================
# GOLD MANAGEMENT
# =============================================================================

func get_gold() -> int:
	return save_data.meta_gold


func add_gold(amount: int) -> void:
	save_data.meta_gold += amount
	save_data.total_gold_earned += amount
	EventBus.meta_gold_changed.emit(save_data.meta_gold)
	save_game()

	# Check for Accountant unlock (10000 total gold)
	if save_data.total_gold_earned >= 10000:
		unlock_character("accountant")


func spend_gold(amount: int) -> bool:
	if save_data.meta_gold >= amount:
		save_data.meta_gold -= amount
		EventBus.meta_gold_changed.emit(save_data.meta_gold)
		save_game()
		return true
	return false

# =============================================================================
# UPGRADES
# =============================================================================

func get_upgrade_level(upgrade_id: String) -> int:
	return save_data.upgrades.get(upgrade_id, 0)


func get_upgrade_cost(upgrade_id: String) -> int:
	var current_level := get_upgrade_level(upgrade_id)
	var base_cost: int = UPGRADE_BASE_COSTS.get(upgrade_id, 100)
	return int(base_cost * pow(UPGRADE_COST_SCALING, current_level))


func can_purchase_upgrade(upgrade_id: String) -> bool:
	# Check max level for revivals
	if upgrade_id == "revivals" and get_upgrade_level(upgrade_id) >= MAX_REVIVAL_LEVEL:
		return false

	return save_data.meta_gold >= get_upgrade_cost(upgrade_id)


func purchase_upgrade(upgrade_id: String) -> bool:
	if not can_purchase_upgrade(upgrade_id):
		return false

	var cost := get_upgrade_cost(upgrade_id)
	if spend_gold(cost):
		save_data.upgrades[upgrade_id] += 1
		EventBus.upgrade_purchased.emit(upgrade_id, save_data.upgrades[upgrade_id])
		save_game()
		return true

	return false


func get_upgrade_bonus(upgrade_id: String) -> float:
	var level := get_upgrade_level(upgrade_id)
	match upgrade_id:
		"max_hp":
			return level * 5.0  # +5 HP per level
		"damage":
			return level * 0.02  # +2% per level
		"move_speed":
			return level * 0.01  # +1% per level
		"xp_gain":
			return level * 0.02  # +2% per level
		"starting_gold":
			return level * 10.0  # +10 gold per level
		"luck":
			return level * 0.01  # +1% per level
		"revivals":
			return float(level)  # Direct count
	return 0.0

# =============================================================================
# CHARACTER UNLOCKS
# =============================================================================

func is_character_unlocked(character_id: String) -> bool:
	return character_id in save_data.unlocked_characters


func unlock_character(character_id: String) -> void:
	if character_id not in save_data.unlocked_characters:
		save_data.unlocked_characters.append(character_id)
		EventBus.character_unlocked.emit(character_id)
		save_game()
		print("[SaveManager] Character unlocked: %s" % character_id)


func get_unlocked_characters() -> Array:
	return save_data.unlocked_characters.duplicate()

# =============================================================================
# ACHIEVEMENTS
# =============================================================================

func is_achievement_unlocked(achievement_id: String) -> bool:
	return achievement_id in save_data.unlocked_achievements


func unlock_achievement(achievement_id: String) -> void:
	if achievement_id not in save_data.unlocked_achievements:
		save_data.unlocked_achievements.append(achievement_id)
		EventBus.achievement_unlocked.emit(achievement_id)
		save_game()
		print("[SaveManager] Achievement unlocked: %s" % achievement_id)


func get_unlocked_achievements() -> Array:
	return save_data.unlocked_achievements.duplicate()

# =============================================================================
# STATISTICS
# =============================================================================

func get_statistic(stat_name: String) -> Variant:
	return save_data.statistics.get(stat_name, 0)


func update_stats(run_stats: Dictionary) -> void:
	save_data.statistics.total_runs += 1
	save_data.statistics.total_kills += run_stats.get("kills", 0)
	save_data.statistics.total_time_played += run_stats.get("time", 0.0)
	save_data.statistics.total_damage_dealt += run_stats.get("damage_dealt", 0)

	if run_stats.get("level", 0) > save_data.statistics.highest_level:
		save_data.statistics.highest_level = run_stats.level

	if run_stats.get("time", 0.0) > save_data.statistics.longest_run:
		save_data.statistics.longest_run = run_stats.time

	_check_stat_unlocks()
	save_game()


func increment_stat(stat_name: String, amount: int = 1) -> void:
	if stat_name in save_data.statistics:
		save_data.statistics[stat_name] += amount
		_check_stat_unlocks()
		save_game()


func record_death() -> void:
	save_data.statistics.total_deaths += 1
	# Check for Gwendolyn unlock (50 deaths)
	if save_data.statistics.total_deaths >= 50:
		unlock_character("gwendolyn")
	save_game()


func record_victory() -> void:
	save_data.statistics.total_victories += 1
	save_game()


func _check_stat_unlocks() -> void:
	# Father Grimsby - Kill 1000 enemies
	if save_data.statistics.total_kills >= 1000:
		unlock_character("grimsby")

	# Patches - Open 50 chests
	if save_data.statistics.chests_opened >= 50:
		unlock_character("patches")

	# Lord Rattington - Kill 500 rats
	if save_data.statistics.rats_killed >= 500:
		unlock_character("rattington")

	# Chef Gusteau - Collect 100 food items
	if save_data.statistics.food_collected >= 100:
		unlock_character("gusteau")

# =============================================================================
# SETTINGS
# =============================================================================

func get_setting(setting_name: String) -> Variant:
	return save_data.settings.get(setting_name, null)


func set_setting(setting_name: String, value: Variant) -> void:
	if setting_name in save_data.settings:
		save_data.settings[setting_name] = value
		save_game()
