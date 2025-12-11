## Player - Main player character controller
## Handles input, components coordination, and state management
class_name Player
extends CharacterBody2D

# =============================================================================
# SIGNALS
# =============================================================================

signal dodge_started
signal dodge_ended
signal hit_taken(damage: int)
signal died

# =============================================================================
# EXPORTS
# =============================================================================

@export var dodge_speed_multiplier: float = 2.5
@export var dodge_duration: float = 0.2
@export var dodge_cooldown: float = 0.8
@export var hit_flash_duration: float = 0.1

# =============================================================================
# NODES
# =============================================================================

@onready var sprite: Sprite2D = $Sprite2D
@onready var shadow_sprite: Sprite2D = $ShadowSprite
@onready var health_component: HealthComponent = $HealthComponent
@onready var movement_component: MovementComponent = $MovementComponent
@onready var stats_component: StatsComponent = $StatsComponent
@onready var hurtbox_area: HurtboxComponent = $HurtboxArea
@onready var pickup_area: Area2D = $PickupArea
@onready var state_machine: StateMachine = $StateMachine
@onready var dodge_cooldown_timer: Timer = $DodgeCooldownTimer
@onready var invincibility_timer: Timer = $InvincibilityTimer
@onready var hit_flash_timer: Timer = $HitFlashTimer

# =============================================================================
# STATE
# =============================================================================

var is_dodging: bool = false
var can_dodge: bool = true
var dodge_direction: Vector2 = Vector2.ZERO
var facing_direction: Vector2 = Vector2.RIGHT

# Visual state
var original_modulate: Color = Color.WHITE
var is_flashing: bool = false

# Character data
var character_data: CharacterData = null

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	_setup_components()
	_connect_signals()
	_create_placeholder_sprite()
	_setup_state_machine()

	# Register with GameManager
	GameManager.register_player(self)

	print("[Player] Initialized at position: %s" % global_position)


func _process(_delta: float) -> void:
	_update_facing_direction()
	_broadcast_position()


func _physics_process(_delta: float) -> void:
	if not is_dodging and GameManager.is_playing():
		_handle_movement_input()
		_handle_dodge_input()

# =============================================================================
# SETUP
# =============================================================================

func _setup_components() -> void:
	# Link hurtbox to health component
	hurtbox_area.health_component = health_component
	hurtbox_area.movement_component = movement_component

	# Apply base stats to movement
	movement_component.max_speed = stats_component.get_move_speed()


func _connect_signals() -> void:
	# Health signals
	health_component.damage_taken.connect(_on_damage_taken)
	health_component.died.connect(_on_died)
	health_component.healed.connect(_on_healed)
	health_component.health_changed.connect(_on_health_changed)
	health_component.revived.connect(_on_revived)

	# Hurtbox signals
	hurtbox_area.hit_received.connect(_on_hit_received)

	# Pickup area
	pickup_area.area_entered.connect(_on_pickup_area_entered)

	# Timers
	dodge_cooldown_timer.timeout.connect(_on_dodge_cooldown_timeout)
	hit_flash_timer.timeout.connect(_on_hit_flash_timeout)

	# Stats changes
	stats_component.stat_changed.connect(_on_stat_changed)


func _create_placeholder_sprite() -> void:
	# Create a simple placeholder texture
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)

	# Draw a simple character shape
	for x in 64:
		for y in 64:
			var color := Color.TRANSPARENT
			var center := Vector2(32, 32)
			var pos := Vector2(x, y)
			var dist := pos.distance_to(center)

			# Body circle
			if dist < 24:
				color = Color(0.4, 0.3, 0.5)  # Purple-ish
			# Head circle
			if pos.distance_to(Vector2(32, 20)) < 12:
				color = Color(0.9, 0.8, 0.7)  # Skin tone
			# Eyes
			if pos.distance_to(Vector2(28, 18)) < 3 or pos.distance_to(Vector2(36, 18)) < 3:
				color = Color(0.2, 0.2, 0.3)

			img.set_pixel(x, y, color)

	var texture := ImageTexture.create_from_image(img)
	sprite.texture = texture
	shadow_sprite.texture = texture


func _setup_state_machine() -> void:
	# Add player states
	var idle_state := preload("res://scenes/player/states/player_idle.gd").new()
	idle_state.name = "Idle"
	state_machine.add_child(idle_state)

	var move_state := preload("res://scenes/player/states/player_move.gd").new()
	move_state.name = "Move"
	state_machine.add_child(move_state)

	var dodge_state := preload("res://scenes/player/states/player_dodge.gd").new()
	dodge_state.name = "Dodge"
	state_machine.add_child(dodge_state)

	var hurt_state := preload("res://scenes/player/states/player_hurt.gd").new()
	hurt_state.name = "Hurt"
	state_machine.add_child(hurt_state)

	var dead_state := preload("res://scenes/player/states/player_dead.gd").new()
	dead_state.name = "Dead"
	state_machine.add_child(dead_state)

	# Set initial state
	state_machine.initial_state = idle_state

# =============================================================================
# INPUT HANDLING
# =============================================================================

func _handle_movement_input() -> void:
	var input_dir := InputManager.get_movement_input()
	movement_component.set_movement_direction(input_dir)


func _handle_dodge_input() -> void:
	if InputManager.is_dodge_pressed() and can_dodge:
		start_dodge()

# =============================================================================
# DODGE SYSTEM
# =============================================================================

func start_dodge() -> void:
	if not can_dodge or is_dodging:
		return

	# Get dodge direction (current movement or facing direction)
	dodge_direction = InputManager.get_movement_input()
	if dodge_direction == Vector2.ZERO:
		dodge_direction = facing_direction
	dodge_direction = dodge_direction.normalized()

	is_dodging = true
	can_dodge = false

	# Make invincible during dodge
	hurtbox_area.set_invincible(dodge_duration)

	# Boost speed
	movement_component.set_speed_multiplier(dodge_speed_multiplier)
	movement_component.set_movement_direction(dodge_direction)

	# Visual feedback
	sprite.modulate = Color(1.0, 1.0, 1.0, 0.5)

	# Transition to dodge state
	state_machine.change_state("Dodge")

	dodge_started.emit()
	EventBus.player_dodged.emit()
	EventBus.sfx_requested.emit("dodge")

	# Start dodge duration timer
	get_tree().create_timer(dodge_duration).timeout.connect(_on_dodge_duration_end)


func _on_dodge_duration_end() -> void:
	is_dodging = false
	movement_component.reset_speed_multiplier()
	sprite.modulate = original_modulate if not is_flashing else Color.WHITE

	# Start cooldown
	dodge_cooldown_timer.start(dodge_cooldown)

	dodge_ended.emit()

	# Return to appropriate state
	if InputManager.is_moving():
		state_machine.change_state("Move")
	else:
		state_machine.change_state("Idle")


func _on_dodge_cooldown_timeout() -> void:
	can_dodge = true

# =============================================================================
# DAMAGE AND DEATH
# =============================================================================

func _on_hit_received(hitbox: HitboxComponent, damage: int, knockback: Vector2, is_crit: bool) -> void:
	if is_dodging:
		return  # Invincible during dodge

	# Transition to hurt state briefly
	if damage > 0:
		state_machine.change_state("Hurt")
		hit_taken.emit(damage)


func _on_damage_taken(amount: int, source: Node) -> void:
	# Hit flash effect
	_start_hit_flash()

	# Screen shake
	EventBus.screen_shake_requested.emit(0.3, 0.15)

	# Sound
	EventBus.sfx_requested.emit("player_hurt")

	# Broadcast
	EventBus.player_damaged.emit(amount, source)


func _on_died() -> void:
	state_machine.change_state("Dead")
	died.emit()

	# Disable input
	InputManager.disable_input()

	print("[Player] Player died!")


func _on_revived() -> void:
	# Re-enable everything
	state_machine.change_state("Idle")
	InputManager.enable_input()

	# Visual feedback
	_start_hit_flash()
	EventBus.screen_shake_requested.emit(0.5, 0.2)
	EventBus.show_notification.emit("Revived!", 2.0)

	print("[Player] Player revived!")


func _on_healed(amount: int) -> void:
	# Green flash for healing
	sprite.modulate = Color(0.5, 1.0, 0.5)
	get_tree().create_timer(0.1).timeout.connect(func(): sprite.modulate = original_modulate)

	EventBus.sfx_requested.emit("heal")


func _on_health_changed(current: int, maximum: int) -> void:
	EventBus.player_health_changed.emit(current, maximum)

# =============================================================================
# VISUAL EFFECTS
# =============================================================================

func _start_hit_flash() -> void:
	is_flashing = true
	sprite.modulate = Color.WHITE
	hit_flash_timer.start(hit_flash_duration)


func _on_hit_flash_timeout() -> void:
	is_flashing = false
	sprite.modulate = original_modulate

# =============================================================================
# PICKUPS
# =============================================================================

func _on_pickup_area_entered(area: Area2D) -> void:
	# Pickups will handle their own collection logic
	if area.has_method("collect"):
		area.collect(self)

# =============================================================================
# STATS
# =============================================================================

func _on_stat_changed(stat_name: String, _old_value: float, new_value: float) -> void:
	match stat_name:
		"move_speed":
			movement_component.max_speed = new_value
		"max_health":
			health_component.set_max_health(int(new_value), true)
		"pickup_radius":
			_update_pickup_radius(new_value)


func _update_pickup_radius(new_radius: float) -> void:
	var shape := pickup_area.get_node("PickupShape") as CollisionShape2D
	if shape and shape.shape is CircleShape2D:
		(shape.shape as CircleShape2D).radius = new_radius

# =============================================================================
# UTILITY
# =============================================================================

func _update_facing_direction() -> void:
	var input_dir := InputManager.get_movement_input()
	if input_dir != Vector2.ZERO:
		facing_direction = input_dir.normalized()

		# Flip sprite based on direction
		sprite.flip_h = facing_direction.x < 0


func _broadcast_position() -> void:
	EventBus.player_position_updated.emit(global_position)


func get_center_position() -> Vector2:
	return global_position


func apply_character_data(data: CharacterData) -> void:
	character_data = data

	# Apply character stat modifiers
	var modifiers := data.get_stat_modifiers()
	for stat_name in modifiers:
		var mod: Dictionary = modifiers[stat_name]
		stats_component.add_modifier(stat_name, "character_%s" % stat_name, mod.type, mod.value)

	# Update health
	health_component.set_max_health(stats_component.get_max_health(), true)

	print("[Player] Applied character data: %s" % data.display_name)
