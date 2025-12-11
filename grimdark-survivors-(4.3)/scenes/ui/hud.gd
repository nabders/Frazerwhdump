## HUD - In-game heads-up display
## Shows health, XP, level, time, and other vital info
class_name HUD
extends CanvasLayer

# =============================================================================
# NODES
# =============================================================================

@onready var health_bar: ProgressBar = $MarginContainer/VBoxContainer/TopBar/HealthBar
@onready var health_label: Label = $MarginContainer/VBoxContainer/TopBar/HealthBar/HealthLabel
@onready var xp_bar: ProgressBar = $MarginContainer/VBoxContainer/TopBar/XPBar
@onready var level_label: Label = $MarginContainer/VBoxContainer/TopBar/LevelLabel
@onready var time_label: Label = $MarginContainer/VBoxContainer/TopBar/TimeLabel
@onready var kills_label: Label = $MarginContainer/VBoxContainer/BottomBar/KillsLabel
@onready var gold_label: Label = $MarginContainer/VBoxContainer/BottomBar/GoldLabel

# =============================================================================
# STATE
# =============================================================================

var current_health: int = 100
var max_health: int = 100
var current_xp: int = 0
var xp_to_level: int = 10

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_connect_signals()
	_update_all_displays()


func _process(_delta: float) -> void:
	if GameManager.is_playing():
		_update_time_display()

# =============================================================================
# SIGNAL CONNECTIONS
# =============================================================================

func _connect_signals() -> void:
	EventBus.player_health_changed.connect(_on_health_changed)
	EventBus.xp_gained.connect(_on_xp_gained)
	EventBus.player_leveled_up.connect(_on_level_up)
	EventBus.enemy_killed.connect(_on_enemy_killed)
	EventBus.gold_collected.connect(_on_gold_collected)
	EventBus.run_started.connect(_on_run_started)

# =============================================================================
# UPDATES
# =============================================================================

func _update_all_displays() -> void:
	_update_health_display()
	_update_xp_display()
	_update_level_display()
	_update_time_display()
	_update_kills_display()
	_update_gold_display()


func _update_health_display() -> void:
	if health_bar:
		health_bar.max_value = max_health
		health_bar.value = current_health

	if health_label:
		health_label.text = "%d / %d" % [current_health, max_health]


func _update_xp_display() -> void:
	if xp_bar:
		xp_bar.max_value = GameManager.xp_to_next_level
		xp_bar.value = GameManager.current_xp


func _update_level_display() -> void:
	if level_label:
		level_label.text = "Lv.%d" % GameManager.current_level


func _update_time_display() -> void:
	if time_label:
		time_label.text = GameManager.get_formatted_time()


func _update_kills_display() -> void:
	if kills_label:
		kills_label.text = "Kills: %d" % GameManager.run_kills


func _update_gold_display() -> void:
	if gold_label:
		gold_label.text = "Gold: %d" % GameManager.run_gold

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_health_changed(current: int, maximum: int) -> void:
	current_health = current
	max_health = maximum
	_update_health_display()

	# Flash health bar on damage
	if health_bar and current < max_health:
		var tween := create_tween()
		tween.tween_property(health_bar, "modulate", Color.RED, 0.05)
		tween.tween_property(health_bar, "modulate", Color.WHITE, 0.1)


func _on_xp_gained(_amount: int) -> void:
	_update_xp_display()

	# Flash XP bar
	if xp_bar:
		var tween := create_tween()
		tween.tween_property(xp_bar, "modulate", Color(1.5, 1.5, 0.5), 0.05)
		tween.tween_property(xp_bar, "modulate", Color.WHITE, 0.1)


func _on_level_up(new_level: int) -> void:
	_update_level_display()
	_update_xp_display()

	# Level up flash effect
	if level_label:
		var tween := create_tween()
		tween.tween_property(level_label, "scale", Vector2(1.3, 1.3), 0.1)
		tween.tween_property(level_label, "scale", Vector2(1.0, 1.0), 0.2)


func _on_enemy_killed(_enemy: Node, _position: Vector2, _xp_value: int) -> void:
	_update_kills_display()


func _on_gold_collected(_amount: int) -> void:
	_update_gold_display()


func _on_run_started() -> void:
	current_health = 100
	max_health = 100
	_update_all_displays()
