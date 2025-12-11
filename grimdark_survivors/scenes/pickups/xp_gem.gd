## XPGem - Experience gem dropped by enemies
## Moves toward player when in pickup radius
class_name XPGem
extends Area2D

# =============================================================================
# EXPORTS
# =============================================================================

@export var xp_value: int = 1
@export var magnet_speed: float = 400.0
@export var magnet_acceleration: float = 1000.0
@export var bob_amplitude: float = 3.0
@export var bob_speed: float = 3.0

# Gem tiers for visual variety
enum GemTier { SMALL, MEDIUM, LARGE, HUGE }
@export var tier: GemTier = GemTier.SMALL

# =============================================================================
# NODES
# =============================================================================

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

# =============================================================================
# STATE
# =============================================================================

var is_being_collected: bool = false
var current_speed: float = 0.0
var target_player: Node2D = null
var initial_y: float = 0.0
var time_alive: float = 0.0

# Tier colors
const TIER_COLORS: Dictionary = {
	GemTier.SMALL: Color(0.3, 0.8, 1.0),   # Cyan
	GemTier.MEDIUM: Color(0.3, 1.0, 0.5),  # Green
	GemTier.LARGE: Color(1.0, 0.8, 0.2),   # Gold
	GemTier.HUGE: Color(1.0, 0.3, 0.8)     # Pink/Magenta
}

const TIER_VALUES: Dictionary = {
	GemTier.SMALL: 1,
	GemTier.MEDIUM: 5,
	GemTier.LARGE: 25,
	GemTier.HUGE: 100
}

const TIER_SCALES: Dictionary = {
	GemTier.SMALL: 0.5,
	GemTier.MEDIUM: 0.7,
	GemTier.LARGE: 1.0,
	GemTier.HUGE: 1.3
}

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	initial_y = position.y
	_setup_visuals()
	_setup_collision()

	# Connect to player pickup area detection
	area_entered.connect(_on_area_entered)


func _process(delta: float) -> void:
	time_alive += delta

	if is_being_collected:
		_move_toward_player(delta)
	else:
		_bob_animation(delta)

# =============================================================================
# SETUP
# =============================================================================

func _setup_visuals() -> void:
	# Create gem texture
	var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
	var color: Color = TIER_COLORS.get(tier, Color.CYAN)

	# Draw diamond shape
	for x in 16:
		for y in 16:
			var center := Vector2(8, 8)
			var pos := Vector2(x, y)

			# Diamond shape using manhattan distance
			var dist := abs(pos.x - center.x) + abs(pos.y - center.y)
			if dist < 7:
				var brightness := 1.0 - (dist / 10.0)
				img.set_pixel(x, y, color * brightness)

	var texture := ImageTexture.create_from_image(img)
	sprite.texture = texture

	# Apply tier scale
	var scale_factor: float = TIER_SCALES.get(tier, 1.0)
	sprite.scale = Vector2(scale_factor, scale_factor)


func _setup_collision() -> void:
	# Set collision layer (pickup layer = 5)
	collision_layer = 16  # Layer 5
	collision_mask = 0    # Doesn't detect anything itself

# =============================================================================
# INITIALIZATION
# =============================================================================

func setup(value: int, spawn_position: Vector2) -> void:
	xp_value = value
	global_position = spawn_position
	initial_y = spawn_position.y

	# Determine tier based on value
	if value >= 100:
		tier = GemTier.HUGE
	elif value >= 25:
		tier = GemTier.LARGE
	elif value >= 5:
		tier = GemTier.MEDIUM
	else:
		tier = GemTier.SMALL

	# Update visuals for tier
	call_deferred("_setup_visuals")


static func create_from_value(value: int) -> XPGem:
	var gem := XPGem.new()
	gem.xp_value = value

	if value >= 100:
		gem.tier = GemTier.HUGE
	elif value >= 25:
		gem.tier = GemTier.LARGE
	elif value >= 5:
		gem.tier = GemTier.MEDIUM
	else:
		gem.tier = GemTier.SMALL

	return gem

# =============================================================================
# ANIMATION
# =============================================================================

func _bob_animation(delta: float) -> void:
	position.y = initial_y + sin(time_alive * bob_speed) * bob_amplitude

# =============================================================================
# MAGNET BEHAVIOR
# =============================================================================

func start_magnet(player: Node2D) -> void:
	if is_being_collected:
		return

	is_being_collected = true
	target_player = player
	current_speed = 50.0  # Start slow


func _move_toward_player(delta: float) -> void:
	if target_player == null:
		is_being_collected = false
		return

	# Accelerate toward player
	current_speed = minf(current_speed + magnet_acceleration * delta, magnet_speed)

	var direction := (target_player.global_position - global_position).normalized()
	global_position += direction * current_speed * delta

	# Check if reached player
	if global_position.distance_to(target_player.global_position) < 20:
		collect(target_player)

# =============================================================================
# COLLECTION
# =============================================================================

func _on_area_entered(area: Area2D) -> void:
	# Start magnet when entering player's pickup area
	var parent := area.get_parent()
	if parent and parent.is_in_group("player"):
		start_magnet(parent)


func collect(collector: Node) -> void:
	if not is_inside_tree():
		return

	# Apply XP multiplier from collector's stats
	var final_xp := xp_value
	if collector.has_node("StatsComponent"):
		var stats: StatsComponent = collector.get_node("StatsComponent")
		final_xp = int(xp_value * stats.get_xp_multiplier())

	# Emit collection event
	EventBus.xp_gem_collected.emit(final_xp)

	# Play sound
	EventBus.sfx_requested.emit("xp_pickup")

	# Collection effect
	_play_collect_effect()

	# Remove gem
	queue_free()


func _play_collect_effect() -> void:
	# Quick scale up and fade (if we had time, could spawn particles)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "scale", sprite.scale * 1.5, 0.1)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.1)
