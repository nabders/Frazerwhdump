## DamageNumbers - Displays floating damage numbers
## Attach to a CanvasLayer for proper rendering
class_name DamageNumbers
extends CanvasLayer

# =============================================================================
# CONSTANTS
# =============================================================================

const FLOAT_SPEED: float = 50.0
const FLOAT_DURATION: float = 0.8
const SPREAD_RANGE: float = 20.0

# Colors
const COLOR_NORMAL: Color = Color.WHITE
const COLOR_CRIT: Color = Color.YELLOW
const COLOR_HEAL: Color = Color.GREEN
const COLOR_PLAYER_DAMAGE: Color = Color.RED

# =============================================================================
# EXPORTS
# =============================================================================

@export var damage_font_size: int = 16
@export var crit_font_size: int = 24
@export var max_numbers: int = 50

# =============================================================================
# STATE
# =============================================================================

var number_pool: Array[Label] = []
var active_numbers: Array[Label] = []

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	layer = 50  # Above most things
	_create_pool()
	_connect_signals()


func _process(delta: float) -> void:
	# Update active numbers
	for label in active_numbers:
		if not is_instance_valid(label):
			continue

		# Move upward
		label.position.y -= FLOAT_SPEED * delta

# =============================================================================
# SETUP
# =============================================================================

func _create_pool() -> void:
	for i in max_numbers:
		var label := Label.new()
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.visible = false
		add_child(label)
		number_pool.append(label)


func _connect_signals() -> void:
	EventBus.damage_dealt.connect(_on_damage_dealt)
	EventBus.player_damaged.connect(_on_player_damaged)

# =============================================================================
# SPAWNING
# =============================================================================

func spawn_number(value: int, world_position: Vector2, is_crit: bool = false, color: Color = COLOR_NORMAL) -> void:
	var label := _get_available_label()
	if label == null:
		return

	# Configure label
	label.text = str(value)
	label.add_theme_font_size_override("font_size", crit_font_size if is_crit else damage_font_size)
	label.modulate = color
	label.modulate.a = 1.0
	label.scale = Vector2(1.5, 1.5) if is_crit else Vector2(1.0, 1.0)

	# Convert world position to screen position
	var camera := get_viewport().get_camera_2d()
	if camera:
		var screen_pos := world_position - camera.global_position + get_viewport().get_visible_rect().size / 2
		# Add random spread
		screen_pos.x += randf_range(-SPREAD_RANGE, SPREAD_RANGE)
		screen_pos.y += randf_range(-SPREAD_RANGE / 2, SPREAD_RANGE / 2)
		label.position = screen_pos
	else:
		label.position = world_position

	# Center the label
	label.position.x -= 20

	# Show and animate
	label.visible = true
	active_numbers.append(label)

	# Animate
	var tween := create_tween()
	tween.set_parallel(true)

	if is_crit:
		# Crit: scale up then down
		tween.tween_property(label, "scale", Vector2(2.0, 2.0), 0.1)
		tween.chain().tween_property(label, "scale", Vector2(1.0, 1.0), 0.2)

	tween.tween_property(label, "modulate:a", 0.0, FLOAT_DURATION).set_delay(FLOAT_DURATION * 0.5)

	# Return to pool after animation
	tween.chain().tween_callback(func(): _return_to_pool(label))


func spawn_heal_number(value: int, world_position: Vector2) -> void:
	spawn_number(value, world_position, false, COLOR_HEAL)

# =============================================================================
# POOL MANAGEMENT
# =============================================================================

func _get_available_label() -> Label:
	for label in number_pool:
		if not label.visible:
			return label

	# Pool exhausted, reuse oldest
	if active_numbers.size() > 0:
		var oldest := active_numbers.pop_front()
		oldest.visible = false
		return oldest

	return null


func _return_to_pool(label: Label) -> void:
	label.visible = false
	active_numbers.erase(label)

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_damage_dealt(amount: int, position: Vector2, is_crit: bool) -> void:
	var color := COLOR_CRIT if is_crit else COLOR_NORMAL
	spawn_number(amount, position, is_crit, color)


func _on_player_damaged(amount: int, _source: Node) -> void:
	var player := GameManager.get_player()
	if player:
		spawn_number(amount, player.global_position, false, COLOR_PLAYER_DAMAGE)
