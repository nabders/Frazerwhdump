## GameManager - Core game state and run management
## Handles game states, run statistics, and game flow
extends Node

# =============================================================================
# CONSTANTS
# =============================================================================

enum GameState {
	MENU,
	PLAYING,
	PAUSED,
	LEVEL_UP,
	GAME_OVER,
	VICTORY
}

const MAX_RUN_TIME: float = 1200.0  # 20 minutes in seconds
const BOSS_TIMES: Array[float] = [300.0, 600.0, 900.0, 1200.0]  # 5, 10, 15, 20 mins

# =============================================================================
# STATE
# =============================================================================

var current_state: GameState = GameState.MENU
var previous_state: GameState = GameState.MENU

# =============================================================================
# RUN DATA
# =============================================================================

var run_time: float = 0.0
var run_kills: int = 0
var run_gold: int = 0
var run_damage_dealt: int = 0
var run_damage_taken: int = 0
var current_level: int = 1
var current_xp: int = 0
var xp_to_next_level: int = 10
var current_minute: int = 0

# Selected character for current run
var current_character_id: String = ""
var current_character_data: Resource = null

# Player reference
var player: Node = null

# =============================================================================
# XP SCALING
# =============================================================================

const BASE_XP_REQUIREMENT: int = 10
const XP_SCALING_FACTOR: float = 1.2

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_connect_signals()
	print("[GameManager] Initialized - Game state: MENU")


func _process(delta: float) -> void:
	if current_state == GameState.PLAYING:
		_update_run_time(delta)


func _connect_signals() -> void:
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.xp_gem_collected.connect(_on_xp_collected)
	EventBus.gold_collected.connect(_on_gold_collected)
	EventBus.player_died.connect(_on_player_died)
	EventBus.level_up_choice_selected.connect(_on_level_up_choice_selected)
	EventBus.damage_dealt.connect(_on_damage_dealt)
	EventBus.player_damaged.connect(_on_player_damaged)

# =============================================================================
# STATE MANAGEMENT
# =============================================================================

func change_state(new_state: GameState) -> void:
	if new_state == current_state:
		return

	previous_state = current_state
	current_state = new_state

	match new_state:
		GameState.PLAYING:
			get_tree().paused = false
		GameState.PAUSED:
			get_tree().paused = true
		GameState.LEVEL_UP:
			get_tree().paused = true
		GameState.GAME_OVER:
			get_tree().paused = true
		GameState.VICTORY:
			get_tree().paused = true

	EventBus.game_state_changed.emit(previous_state, new_state)
	print("[GameManager] State changed: %s -> %s" % [GameState.keys()[previous_state], GameState.keys()[new_state]])


func is_playing() -> bool:
	return current_state == GameState.PLAYING


func is_paused() -> bool:
	return current_state == GameState.PAUSED or current_state == GameState.LEVEL_UP

# =============================================================================
# RUN MANAGEMENT
# =============================================================================

func start_run(character_id: String) -> void:
	_reset_run_data()
	current_character_id = character_id
	# Character data would be loaded here from SaveManager
	change_state(GameState.PLAYING)
	EventBus.run_started.emit()
	print("[GameManager] Run started with character: %s" % character_id)


func end_run(victory: bool) -> void:
	var stats := get_run_stats()

	if victory:
		change_state(GameState.VICTORY)
	else:
		change_state(GameState.GAME_OVER)

	# Award gold to meta progression
	SaveManager.add_gold(run_gold)

	# Track statistics
	SaveManager.update_stats(stats)

	EventBus.run_ended.emit(victory, stats)
	print("[GameManager] Run ended - Victory: %s" % victory)


func _reset_run_data() -> void:
	run_time = 0.0
	run_kills = 0
	run_gold = 0
	run_damage_dealt = 0
	run_damage_taken = 0
	current_level = 1
	current_xp = 0
	xp_to_next_level = BASE_XP_REQUIREMENT
	current_minute = 0


func get_run_stats() -> Dictionary:
	return {
		"time": run_time,
		"kills": run_kills,
		"gold": run_gold,
		"damage_dealt": run_damage_dealt,
		"damage_taken": run_damage_taken,
		"level": current_level,
		"character": current_character_id
	}

# =============================================================================
# TIME MANAGEMENT
# =============================================================================

func _update_run_time(delta: float) -> void:
	run_time += delta

	# Check for minute passing
	var new_minute := int(run_time / 60.0)
	if new_minute > current_minute:
		current_minute = new_minute
		EventBus.minute_passed.emit(current_minute)
		print("[GameManager] Minute %d reached" % current_minute)

		# Check for boss spawn times
		var boss_minute := current_minute * 60.0
		if boss_minute in BOSS_TIMES:
			_trigger_boss_spawn(BOSS_TIMES.find(boss_minute))

	# Check for victory condition
	if run_time >= MAX_RUN_TIME:
		end_run(true)


func _trigger_boss_spawn(boss_index: int) -> void:
	# This will be handled by the spawner system
	print("[GameManager] Boss %d should spawn!" % (boss_index + 1))

# =============================================================================
# XP AND LEVELING
# =============================================================================

func add_xp(amount: int) -> void:
	var modified_amount := amount
	# Apply XP modifiers from stats component when available

	current_xp += modified_amount
	EventBus.xp_gained.emit(modified_amount)

	# Check for level up
	while current_xp >= xp_to_next_level:
		_level_up()


func _level_up() -> void:
	current_xp -= xp_to_next_level
	current_level += 1
	xp_to_next_level = _calculate_xp_requirement(current_level)

	EventBus.player_leveled_up.emit(current_level)
	print("[GameManager] Level up! Now level %d" % current_level)

	# Trigger level up choice UI
	_show_level_up_choices()


func _calculate_xp_requirement(level: int) -> int:
	return int(BASE_XP_REQUIREMENT * pow(XP_SCALING_FACTOR, level - 1))


func _show_level_up_choices() -> void:
	change_state(GameState.LEVEL_UP)
	# Generate random choices - this will be expanded with the weapon/item system
	var choices: Array = []
	# TODO: Generate actual choices from available weapons/items
	EventBus.show_level_up_choices.emit(choices)

# =============================================================================
# PAUSE MANAGEMENT
# =============================================================================

func toggle_pause() -> void:
	if current_state == GameState.PLAYING:
		change_state(GameState.PAUSED)
		EventBus.game_paused.emit()
	elif current_state == GameState.PAUSED:
		change_state(GameState.PLAYING)
		EventBus.game_unpaused.emit()


func pause() -> void:
	if current_state == GameState.PLAYING:
		change_state(GameState.PAUSED)
		EventBus.game_paused.emit()


func unpause() -> void:
	if current_state == GameState.PAUSED:
		change_state(GameState.PLAYING)
		EventBus.game_unpaused.emit()

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_enemy_killed(_enemy: Node, _position: Vector2, _xp_value: int) -> void:
	run_kills += 1


func _on_xp_collected(value: int) -> void:
	add_xp(value)


func _on_gold_collected(amount: int) -> void:
	run_gold += amount


func _on_player_died() -> void:
	end_run(false)


func _on_level_up_choice_selected(_choice_index: int) -> void:
	if current_state == GameState.LEVEL_UP:
		change_state(GameState.PLAYING)


func _on_damage_dealt(amount: int, _position: Vector2, _is_crit: bool) -> void:
	run_damage_dealt += amount


func _on_player_damaged(amount: int, _source: Node) -> void:
	run_damage_taken += amount

# =============================================================================
# UTILITY
# =============================================================================

func get_formatted_time() -> String:
	var minutes: int = int(run_time / 60)
	var seconds: int = int(run_time) % 60
	return "%02d:%02d" % [minutes, seconds]


func register_player(player_node: Node) -> void:
	player = player_node
	print("[GameManager] Player registered")


func get_player() -> Node:
	return player
