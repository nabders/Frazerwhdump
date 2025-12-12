## GameOverScreen - Displays when player dies
class_name GameOverScreen
extends CanvasLayer

# =============================================================================
# NODES
# =============================================================================

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var stats_label: Label = $Panel/VBoxContainer/StatsLabel
@onready var gold_label: Label = $Panel/VBoxContainer/GoldLabel
@onready var continue_button: Button = $Panel/VBoxContainer/ContinueButton

# =============================================================================
# STATE
# =============================================================================

var is_victory: bool = false

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	layer = 40
	visible = false
	_connect_signals()

# =============================================================================
# SETUP
# =============================================================================

func _connect_signals() -> void:
	EventBus.run_ended.connect(_on_run_ended)
	continue_button.pressed.connect(_on_continue)

# =============================================================================
# DISPLAY
# =============================================================================

func show_screen(victory: bool, stats: Dictionary) -> void:
	is_victory = victory
	visible = true

	if victory:
		title_label.text = "VICTORY!"
		title_label.modulate = Color.GOLD
	else:
		title_label.text = "YOU DIED"
		title_label.modulate = Color.RED

	_update_stats(stats)

	# Re-enable input after delay
	await get_tree().create_timer(0.5).timeout
	continue_button.grab_focus()


func hide_screen() -> void:
	visible = false


func _update_stats(stats: Dictionary) -> void:
	var text := ""
	text += "Time Survived: %s\n" % _format_time(stats.get("time", 0))
	text += "Level Reached: %d\n" % stats.get("level", 1)
	text += "Enemies Killed: %d\n" % stats.get("kills", 0)
	text += "Damage Dealt: %d\n" % stats.get("damage_dealt", 0)
	stats_label.text = text

	var gold := stats.get("gold", 0)
	gold_label.text = "Gold Earned: +%d" % gold


func _format_time(seconds: float) -> String:
	var mins: int = int(seconds / 60)
	var secs: int = int(seconds) % 60
	return "%02d:%02d" % [mins, secs]

# =============================================================================
# ACTIONS
# =============================================================================

func _on_continue() -> void:
	hide_screen()
	# Reset to menu state
	get_tree().paused = false
	GameManager.change_state(GameManager.GameState.MENU)
	# Reload the scene for a fresh start
	get_tree().reload_current_scene()

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_run_ended(victory: bool, stats: Dictionary) -> void:
	# Small delay before showing
	await get_tree().create_timer(1.0).timeout
	show_screen(victory, stats)
