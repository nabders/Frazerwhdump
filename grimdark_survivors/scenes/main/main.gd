## Main - Entry point and scene manager
## Handles scene transitions and game initialization
extends Node2D

# =============================================================================
# PRELOADS
# =============================================================================

const XPGemScene := preload("res://scenes/pickups/xp_gem.tscn")

# =============================================================================
# NODES
# =============================================================================

@onready var world: Node2D = $World
@onready var player: Player = $World/Player
@onready var enemies_container: Node2D = $World/Enemies
@onready var pickups_container: Node2D = $World/Pickups
@onready var projectiles_container: Node2D = $World/Projectiles
@onready var camera: CameraController = $Camera2D
@onready var hud: HUD = $HUD
@onready var debug_label: Label = $DebugLayer/DebugLabel
@onready var fps_label: Label = $DebugLayer/FPSLabel

# =============================================================================
# STATE
# =============================================================================

var xp_spawn_timer: float = 0.0
const XP_SPAWN_INTERVAL: float = 2.0  # Debug: spawn XP gems periodically

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	print("[Main] Grimdark Survivors initialized")
	print("[Main] Godot version: %s" % Engine.get_version_info().string)

	_connect_signals()
	_setup_camera()
	_update_debug_label()

	# Auto-start run for testing
	call_deferred("_auto_start_run")


func _process(delta: float) -> void:
	_update_fps_label()

	# Debug: spawn XP gems for testing
	if GameManager.is_playing():
		xp_spawn_timer += delta
		if xp_spawn_timer >= XP_SPAWN_INTERVAL:
			xp_spawn_timer = 0.0
			_spawn_test_xp_gems()


func _unhandled_input(event: InputEvent) -> void:
	# Debug: Start a test run with E
	if event.is_action_pressed("interact"):
		if GameManager.current_state == GameManager.GameState.MENU:
			_start_test_run()

	# Debug: Spawn XP gems manually with number keys
	if event.is_action_pressed("select_1") and GameManager.is_playing():
		_spawn_xp_at_random_position(1)
	if event.is_action_pressed("select_2") and GameManager.is_playing():
		_spawn_xp_at_random_position(5)
	if event.is_action_pressed("select_3") and GameManager.is_playing():
		_spawn_xp_at_random_position(25)

# =============================================================================
# SETUP
# =============================================================================

func _setup_camera() -> void:
	if camera and player:
		camera.follow_target = player
		camera.snap_to_target()


func _connect_signals() -> void:
	EventBus.game_state_changed.connect(_on_game_state_changed)
	EventBus.run_started.connect(_on_run_started)
	EventBus.run_ended.connect(_on_run_ended)
	EventBus.player_leveled_up.connect(_on_player_leveled_up)
	EventBus.enemy_killed.connect(_on_enemy_killed)

# =============================================================================
# GAME FLOW
# =============================================================================

func _auto_start_run() -> void:
	# Wait a frame then auto-start for testing
	await get_tree().process_frame
	if GameManager.current_state == GameManager.GameState.MENU:
		_start_test_run()


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
	_setup_camera()


func _on_run_ended(victory: bool, stats: Dictionary) -> void:
	print("[Main] Run ended - Victory: %s" % victory)
	print("[Main] Stats: %s" % stats)
	_update_debug_label()


func _on_player_leveled_up(new_level: int) -> void:
	print("[Main] Player reached level %d!" % new_level)


func _on_enemy_killed(enemy: Node, position: Vector2, xp_value: int) -> void:
	# Spawn XP gem at enemy death position
	spawn_xp_gem(xp_value, position)

# =============================================================================
# SPAWNING
# =============================================================================

func spawn_xp_gem(value: int, position: Vector2) -> void:
	var gem: XPGem = XPGemScene.instantiate()
	gem.setup(value, position)
	pickups_container.add_child(gem)


func _spawn_test_xp_gems() -> void:
	if player == null:
		return

	# Spawn a few XP gems around the player for testing
	var spawn_count := randi_range(1, 3)
	for i in spawn_count:
		var offset := Vector2(randf_range(-300, 300), randf_range(-300, 300))
		var spawn_pos := player.global_position + offset
		var value := [1, 1, 1, 5, 5, 25].pick_random()  # Weighted random
		spawn_xp_gem(value, spawn_pos)


func _spawn_xp_at_random_position(value: int) -> void:
	if player == null:
		return

	var offset := Vector2(randf_range(-200, 200), randf_range(-200, 200))
	spawn_xp_gem(value, player.global_position + offset)

# =============================================================================
# UI UPDATES
# =============================================================================

func _update_debug_label() -> void:
	var state_name := GameManager.GameState.keys()[GameManager.current_state]
	var gold := SaveManager.get_gold()

	var text := "Grimdark Survivors - Dev Build\n"
	text += "State: %s | Meta Gold: %d\n" % [state_name, gold]

	if GameManager.current_state == GameManager.GameState.MENU:
		text += "\nPress E to start"
	elif GameManager.current_state == GameManager.GameState.PLAYING:
		text += "\nWASD: Move | Space: Dodge"
		text += "\n1/2/3: Spawn XP (1/5/25)"
	elif GameManager.current_state == GameManager.GameState.PAUSED:
		text += "\nPAUSED - Tab to resume"

	debug_label.text = text


func _update_fps_label() -> void:
	fps_label.text = "FPS: %d" % Engine.get_frames_per_second()

# =============================================================================
# UTILITY
# =============================================================================

func get_enemies_container() -> Node2D:
	return enemies_container


func get_pickups_container() -> Node2D:
	return pickups_container


func get_projectiles_container() -> Node2D:
	return projectiles_container
