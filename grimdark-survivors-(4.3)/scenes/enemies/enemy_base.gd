## EnemyBase - Base class for all enemies
## Handles common enemy behavior, components, and death
class_name EnemyBase
extends CharacterBody2D

# =============================================================================
# SIGNALS
# =============================================================================

signal died(enemy: EnemyBase)
signal damaged(amount: int)

# =============================================================================
# EXPORTS
# =============================================================================

@export var enemy_data: EnemyData = null
@export var xp_value: int = 1
@export var contact_damage: int = 5
@export var move_speed: float = 80.0
@export var detection_range: float = 500.0

# =============================================================================
# NODES
# =============================================================================

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var health_component: HealthComponent = $HealthComponent
@onready var movement_component: MovementComponent = $MovementComponent
@onready var hurtbox: HurtboxComponent = $HurtboxArea
@onready var hitbox: HitboxComponent = $HitboxArea

# =============================================================================
# STATE
# =============================================================================

var target: Node2D = null
var is_dead: bool = false
var spawn_minute: int = 0  # For scaling

# Visual
var original_modulate: Color = Color.WHITE
var flash_timer: float = 0.0

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	add_to_group("enemy")
	_setup_components()
	_connect_signals()
	_create_placeholder_sprite()
	_find_target()

	# Apply time-based scaling
	spawn_minute = GameManager.current_minute
	_apply_scaling()


func _process(delta: float) -> void:
	_update_flash(delta)


func _physics_process(delta: float) -> void:
	if is_dead:
		return

	_update_ai(delta)

# =============================================================================
# SETUP
# =============================================================================

func _setup_components() -> void:
	# Configure health
	if health_component:
		health_component.max_health = _get_scaled_health()
		health_component.starting_health = -1  # Use max

	# Configure movement
	if movement_component:
		movement_component.max_speed = move_speed
		movement_component.use_acceleration = false  # Enemies move at constant speed

	# Configure hitbox (contact damage)
	if hitbox:
		hitbox.damage = contact_damage
		hitbox.knockback_force = 150.0

	# Configure hurtbox
	if hurtbox:
		hurtbox.health_component = health_component
		hurtbox.movement_component = movement_component


func _connect_signals() -> void:
	if health_component:
		health_component.damage_taken.connect(_on_damage_taken)
		health_component.died.connect(_on_died)

	if hurtbox:
		hurtbox.hit_received.connect(_on_hit_received)


func _create_placeholder_sprite() -> void:
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var color := Color(0.6, 0.4, 0.4)  # Reddish brown for enemies

	# Draw simple enemy shape
	for x in 32:
		for y in 32:
			var center := Vector2(16, 16)
			var pos := Vector2(x, y)
			var dist := pos.distance_to(center)

			if dist < 14:
				var brightness := 1.0 - (dist / 20.0)
				img.set_pixel(x, y, color * brightness)

			# Evil eyes
			if pos.distance_to(Vector2(12, 12)) < 3 or pos.distance_to(Vector2(20, 12)) < 3:
				img.set_pixel(x, y, Color.RED)

	var texture := ImageTexture.create_from_image(img)
	sprite.texture = texture


func _find_target() -> void:
	target = GameManager.get_player()

# =============================================================================
# SCALING
# =============================================================================

func _apply_scaling() -> void:
	if enemy_data:
		var scaled := enemy_data.get_scaled_stats(spawn_minute)
		if health_component:
			health_component.max_health = scaled.max_health
			health_component.current_health = scaled.max_health
		contact_damage = scaled.damage
		move_speed = scaled.move_speed
		if hitbox:
			hitbox.damage = contact_damage


func _get_scaled_health() -> int:
	if enemy_data:
		return enemy_data.get_health_at_minute(spawn_minute)
	return 10 + (spawn_minute * 2)  # Default scaling

# =============================================================================
# AI
# =============================================================================

func _update_ai(_delta: float) -> void:
	if target == null:
		_find_target()
		return

	# Simple chase behavior
	var direction := (target.global_position - global_position).normalized()
	movement_component.set_movement_direction(direction)

	# Flip sprite based on movement
	if direction.x != 0:
		sprite.flip_h = direction.x < 0

# =============================================================================
# DAMAGE
# =============================================================================

func _on_hit_received(_hitbox: HitboxComponent, damage: int, _knockback: Vector2, is_crit: bool) -> void:
	_start_flash()
	damaged.emit(damage)


func _on_damage_taken(amount: int, source: Node) -> void:
	EventBus.enemy_damaged.emit(self, amount, source)


func _start_flash() -> void:
	sprite.modulate = Color.WHITE
	flash_timer = 0.1


func _update_flash(delta: float) -> void:
	if flash_timer > 0:
		flash_timer -= delta
		if flash_timer <= 0:
			sprite.modulate = original_modulate

# =============================================================================
# DEATH
# =============================================================================

func _on_died() -> void:
	if is_dead:
		return

	is_dead = true

	# Disable collision
	collision_shape.set_deferred("disabled", true)
	if hitbox:
		hitbox.deactivate()
	if hurtbox:
		hurtbox.deactivate()

	# Stop movement
	movement_component.stop()

	# Emit signals
	died.emit(self)
	EventBus.enemy_killed.emit(self, global_position, xp_value)

	# Death animation
	_play_death_animation()


func _play_death_animation() -> void:
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
	tween.tween_property(sprite, "scale", Vector2(1.5, 0.2), 0.3)
	tween.tween_property(self, "position:y", position.y + 10, 0.3)
	tween.chain().tween_callback(queue_free)

# =============================================================================
# UTILITY
# =============================================================================

func setup_from_data(data: EnemyData, minute: int = 0) -> void:
	enemy_data = data
	spawn_minute = minute

	xp_value = data.xp_value
	contact_damage = data.damage
	move_speed = data.move_speed
	detection_range = data.detection_range

	call_deferred("_apply_scaling")


func get_xp_value() -> int:
	return xp_value
