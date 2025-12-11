## HurtboxComponent - Receives damage from HitboxComponents
## Attach as a child of Area2D that represents the entity's vulnerable area
class_name HurtboxComponent
extends Area2D

# =============================================================================
# SIGNALS
# =============================================================================

signal hit_received(hitbox: HitboxComponent, damage: int, knockback: Vector2, is_crit: bool)
signal invincibility_started
signal invincibility_ended

# =============================================================================
# EXPORTS
# =============================================================================

@export var is_active: bool = true
@export var health_component: HealthComponent = null
@export var movement_component: Node = null  # For knockback application
@export var damage_reduction: float = 0.0  # Flat reduction
@export var damage_resistance: float = 0.0  # Percentage reduction (0.0 - 1.0)

# =============================================================================
# STATE
# =============================================================================

var owner_entity: Node = null
var is_invincible: bool = false

# Resistance to specific damage types (0.0 = normal, 1.0 = immune, negative = weak)
var type_resistances: Dictionary = {
	"physical": 0.0,
	"fire": 0.0,
	"ice": 0.0,
	"lightning": 0.0,
	"poison": 0.0,
	"holy": 0.0
}

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	owner_entity = get_parent().get_parent() if get_parent() else null

	# Auto-find health component if not set
	if health_component == null and owner_entity:
		health_component = owner_entity.get_node_or_null("HealthComponent")

	# Auto-find movement component if not set
	if movement_component == null and owner_entity:
		movement_component = owner_entity.get_node_or_null("MovementComponent")

	# Connect to health component invincibility
	if health_component:
		health_component.damage_taken.connect(_on_health_damage_taken)

	_setup_collision_layers()


func _setup_collision_layers() -> void:
	# Hurtboxes are detected by hitboxes
	if owner_entity:
		if owner_entity.is_in_group("player"):
			collision_layer = 4  # Player hurtbox layer
			collision_mask = 0   # Hurtboxes don't detect anything
		elif owner_entity.is_in_group("enemy"):
			collision_layer = 8  # Enemy hurtbox layer
			collision_mask = 0

# =============================================================================
# HIT HANDLING
# =============================================================================

func receive_hit(hitbox: HitboxComponent, raw_damage: int, knockback: Vector2, is_crit: bool) -> void:
	if not is_active or is_invincible:
		return

	# Calculate final damage after resistances
	var final_damage := _calculate_final_damage(raw_damage, hitbox.damage_type)

	# Emit hit received signal
	hit_received.emit(hitbox, final_damage, knockback, is_crit)

	# Apply damage to health component
	if health_component and final_damage > 0:
		health_component.take_damage(final_damage, hitbox.owner_entity)

	# Apply knockback to movement component
	if movement_component and knockback != Vector2.ZERO:
		if movement_component.has_method("apply_knockback"):
			movement_component.apply_knockback(knockback)

	# Visual/audio feedback
	_trigger_hit_effects(final_damage, is_crit)


func _calculate_final_damage(raw_damage: int, damage_type: String) -> int:
	var damage := float(raw_damage)

	# Apply type resistance
	var type_resist: float = type_resistances.get(damage_type, 0.0)
	damage *= (1.0 - type_resist)

	# Apply general damage resistance
	damage *= (1.0 - damage_resistance)

	# Apply flat reduction
	damage -= damage_reduction

	return maxi(0, int(damage))


func _trigger_hit_effects(damage: int, is_crit: bool) -> void:
	if owner_entity == null:
		return

	# Request damage number display
	EventBus.damage_dealt.emit(damage, owner_entity.global_position, is_crit)

	# Play hit sound
	EventBus.sfx_requested.emit("hit")

	# Screen shake for significant hits
	if damage >= 20 or is_crit:
		var shake_intensity := 0.5 if is_crit else 0.3
		EventBus.screen_shake_requested.emit(shake_intensity, 0.1)


func _on_health_damage_taken(_amount: int, _source: Node) -> void:
	# Sync invincibility with health component
	if health_component and health_component.is_invincible:
		set_invincible(health_component.invincibility_time)

# =============================================================================
# INVINCIBILITY
# =============================================================================

func set_invincible(duration: float) -> void:
	if duration <= 0.0:
		return

	is_invincible = true
	invincibility_started.emit()

	# Use a timer to clear invincibility
	get_tree().create_timer(duration).timeout.connect(
		func(): _end_invincibility(),
		CONNECT_ONE_SHOT
	)


func _end_invincibility() -> void:
	is_invincible = false
	invincibility_ended.emit()


func clear_invincibility() -> void:
	is_invincible = false

# =============================================================================
# RESISTANCE MANAGEMENT
# =============================================================================

func set_type_resistance(damage_type: String, resistance: float) -> void:
	type_resistances[damage_type] = clampf(resistance, -1.0, 1.0)


func add_type_resistance(damage_type: String, amount: float) -> void:
	var current: float = type_resistances.get(damage_type, 0.0)
	type_resistances[damage_type] = clampf(current + amount, -1.0, 1.0)


func set_all_resistances(resistance: float) -> void:
	for damage_type in type_resistances:
		type_resistances[damage_type] = clampf(resistance, -1.0, 1.0)


func get_type_resistance(damage_type: String) -> float:
	return type_resistances.get(damage_type, 0.0)

# =============================================================================
# CONTROL
# =============================================================================

func activate() -> void:
	is_active = true


func deactivate() -> void:
	is_active = false
