## HitboxComponent - Deals damage to HurtboxComponents
## Attach as a child of Area2D that represents the attack hitbox
class_name HitboxComponent
extends Area2D

# =============================================================================
# SIGNALS
# =============================================================================

signal hit_landed(hurtbox: HurtboxComponent)

# =============================================================================
# EXPORTS
# =============================================================================

@export var damage: int = 10
@export var knockback_force: float = 100.0
@export var hit_stun_duration: float = 0.0
@export var is_active: bool = true
@export var can_hit_multiple: bool = true  # Can hit multiple targets per activation
@export var hits_per_target: int = 1  # How many times can hit same target (0 = unlimited)
@export var hit_cooldown: float = 0.0  # Time between hits on same target

# Damage type for elemental effects
@export_enum("physical", "fire", "ice", "lightning", "poison", "holy") var damage_type: String = "physical"

# =============================================================================
# STATE
# =============================================================================

var owner_entity: Node = null
var hit_targets: Dictionary = {}  # target_id: {count: int, last_hit_time: float}

# Damage modifiers (set by StatsComponent or buffs)
var damage_multiplier: float = 1.0
var knockback_multiplier: float = 1.0
var is_crit: bool = false

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	owner_entity = get_parent().get_parent() if get_parent() else null

	# Connect to area signals
	area_entered.connect(_on_area_entered)

	# Set collision layers based on owner
	_setup_collision_layers()


func _setup_collision_layers() -> void:
	# Default: hitboxes look for hurtboxes
	# Player hitboxes (layer 3) look for enemy hurtboxes (layer 4)
	# Enemy hitboxes (layer 4) look for player hurtboxes (layer 3)

	if owner_entity:
		if owner_entity.is_in_group("player"):
			collision_layer = 4  # Player hitbox layer
			collision_mask = 8   # Enemy hurtbox layer
		elif owner_entity.is_in_group("enemy"):
			collision_layer = 8  # Enemy hitbox layer
			collision_mask = 4   # Player hurtbox layer

# =============================================================================
# COLLISION HANDLING
# =============================================================================

func _on_area_entered(area: Area2D) -> void:
	if not is_active:
		return

	if area is HurtboxComponent:
		_try_hit(area as HurtboxComponent)


func _try_hit(hurtbox: HurtboxComponent) -> void:
	if not hurtbox.is_active:
		return

	# Check if we can hit this target
	var target_id := hurtbox.get_instance_id()

	if target_id in hit_targets:
		var hit_data: Dictionary = hit_targets[target_id]

		# Check hit count limit
		if hits_per_target > 0 and hit_data.count >= hits_per_target:
			return

		# Check hit cooldown
		if hit_cooldown > 0.0:
			var time_since_hit := Time.get_ticks_msec() / 1000.0 - hit_data.last_hit_time
			if time_since_hit < hit_cooldown:
				return

	# Calculate final damage
	var final_damage := _calculate_damage()

	# Calculate knockback direction
	var knockback_dir := Vector2.ZERO
	if owner_entity and hurtbox.owner_entity:
		knockback_dir = (hurtbox.owner_entity.global_position - owner_entity.global_position).normalized()

	# Apply the hit
	hurtbox.receive_hit(self, final_damage, knockback_dir * knockback_force * knockback_multiplier, is_crit)

	# Track the hit
	_record_hit(target_id)

	# Emit signal
	hit_landed.emit(hurtbox)

	# Broadcast hit for effects/sounds
	EventBus.hit_registered.emit(owner_entity, hurtbox.owner_entity, final_damage)


func _calculate_damage() -> int:
	var base := float(damage) * damage_multiplier

	# Crit calculation would happen here based on stats
	is_crit = false  # Will be set by StatsComponent

	return int(base)


func _record_hit(target_id: int) -> void:
	var current_time := Time.get_ticks_msec() / 1000.0

	if target_id in hit_targets:
		hit_targets[target_id].count += 1
		hit_targets[target_id].last_hit_time = current_time
	else:
		hit_targets[target_id] = {
			"count": 1,
			"last_hit_time": current_time
		}

# =============================================================================
# CONTROL
# =============================================================================

func activate() -> void:
	is_active = true
	reset_hits()


func deactivate() -> void:
	is_active = false


func reset_hits() -> void:
	hit_targets.clear()


func reset_hits_for_target(target: Node) -> void:
	var target_id := target.get_instance_id()
	hit_targets.erase(target_id)

# =============================================================================
# CONFIGURATION
# =============================================================================

func set_damage(new_damage: int) -> void:
	damage = new_damage


func set_knockback(new_force: float) -> void:
	knockback_force = new_force


func configure(new_damage: int, new_knockback: float = -1.0, new_damage_type: String = "") -> void:
	damage = new_damage
	if new_knockback >= 0.0:
		knockback_force = new_knockback
	if new_damage_type != "":
		damage_type = new_damage_type
