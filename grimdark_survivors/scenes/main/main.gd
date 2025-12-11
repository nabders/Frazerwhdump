## Main - Entry point and scene manager
## Handles scene transitions and game initialization
extends Node2D

# =============================================================================
# NODES
# =============================================================================

@onready var camera: Camera2D = $Camera2D
@onready var debug_label: Label = $CanvasLayer/DebugLabel
@onready var fps_label: Label = $CanvasLayer/FPSLabel

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	print("[Main] Grimdark Survivors initialized")
	print("[Main] Godot version: %s" % Engine.get_version_info().string)

	_connect_signals()
	_update_debug_label()


func _process(_delta: float) -> void:
	_update_fps_label()


func _unhandled_input(event: InputEvent) -> void:
	# Debug: Start a test run with E
	if event.is_action_pressed("interact"):
		if GameManager.current_state == GameManager.GameState.MENU:
			_start_test_run()

# =============================================================================
# SIGNAL CONNECTIONS
# =============================================================================

func _connect_signals() -> void:
	EventBus.game_state_changed.connect(_on_game_state_changed)
	EventBus.run_started.connect(_on_run_started)
	EventBus.run_ended.connect(_on_run_ended)
	EventBus.player_leveled_up.connect(_on_player_leveled_up)

# =============================================================================
# GAME FLOW
# =============================================================================

func _start_test_run() -> void:
	print("[Main] Starting test run...")
	GameManager.start_run("knight")
	_update_debug_label()


func _on_game_state_changed(old_state: int, new_state: int) -> void:
	print("[Main] Game state: %s -> %s" % [
		GameManager.GameState.keys()[old_state],
		GameManager.GameState.keys()[new_state]
	])
	_update_debug_label()


func _on_run_started() -> void:
	print("[Main] Run started!")


func _on_run_ended(victory: bool, stats: Dictionary) -> void:
	print("[Main] Run ended - Victory: %s" % victory)
	print("[Main] Stats: %s" % stats)
	_update_debug_label()


func _on_player_leveled_up(new_level: int) -> void:
	print("[Main] Player reached level %d!" % new_level)

# =============================================================================
# UI UPDATES
# =============================================================================

func _update_debug_label() -> void:
	var state_name := GameManager.GameState.keys()[GameManager.current_state]
	var gold := SaveManager.get_gold()

	var text := "Grimdark Survivors - Development Build\n"
	text += "State: %s\n" % state_name
	text += "Meta Gold: %d\n" % gold
	text += "\n"

	if GameManager.current_state == GameManager.GameState.MENU:
		text += "Press E to start a test run\n"
		text += "Press Tab to pause\n"
	elif GameManager.current_state == GameManager.GameState.PLAYING:
		text += "Time: %s\n" % GameManager.get_formatted_time()
		text += "Level: %d\n" % GameManager.current_level
		text += "Kills: %d\n" % GameManager.run_kills
		text += "\nPress Tab to pause\n"
	elif GameManager.current_state == GameManager.GameState.PAUSED:
		text += "PAUSED\n"
		text += "Press Tab to resume\n"

	debug_label.text = text


func _update_fps_label() -> void:
	fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
