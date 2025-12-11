## PauseMenu - Displays when game is paused
class_name PauseMenu
extends CanvasLayer

# =============================================================================
# NODES
# =============================================================================

@onready var panel: PanelContainer = $Panel
@onready var resume_button: Button = $Panel/VBoxContainer/ResumeButton
@onready var quit_button: Button = $Panel/VBoxContainer/QuitButton
@onready var stats_label: Label = $Panel/VBoxContainer/StatsLabel

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	layer = 30
	visible = false
	_connect_signals()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		_resume()
		get_viewport().set_input_as_handled()

# =============================================================================
# SETUP
# =============================================================================

func _connect_signals() -> void:
	EventBus.game_paused.connect(_on_game_paused)
	EventBus.game_unpaused.connect(_on_game_unpaused)
	resume_button.pressed.connect(_resume)
	quit_button.pressed.connect(_quit)

# =============================================================================
# DISPLAY
# =============================================================================

func show_menu() -> void:
	visible = true
	_update_stats()


func hide_menu() -> void:
	visible = false


func _update_stats() -> void:
	var text := "Run Stats:\n"
	text += "Time: %s\n" % GameManager.get_formatted_time()
	text += "Level: %d\n" % GameManager.current_level
	text += "Kills: %d\n" % GameManager.run_kills
	text += "Gold: %d\n" % GameManager.run_gold
	stats_label.text = text

# =============================================================================
# ACTIONS
# =============================================================================

func _resume() -> void:
	GameManager.unpause()


func _quit() -> void:
	# End run as loss
	GameManager.end_run(false)

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_game_paused() -> void:
	show_menu()


func _on_game_unpaused() -> void:
	hide_menu()
