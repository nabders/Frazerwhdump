## RustySword - Basic melee sweep weapon
## Attacks in an arc in front of the player
class_name RustySword
extends WeaponBase

# =============================================================================
# CONSTANTS
# =============================================================================

const SWEEP_ARC: float = 120.0  # Degrees
const SWEEP_RANGE: float = 60.0  # Base range
const SWEEP_DURATION: float = 0.15  # Visual duration

# =============================================================================
# NODES
# =============================================================================

@onready var sweep_area: Area2D = $SweepArea
@onready var sweep_shape: CollisionShape2D = $SweepArea/CollisionShape2D
@onready var sweep_visual: Node2D = $SweepVisual

# =============================================================================
# STATE
# =============================================================================

var is_attacking: bool = false
var attack_direction: Vector2 = Vector2.RIGHT
var enemies_hit: Array = []

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	super._ready()
	_setup_sweep_area()

	# Set default stats if no weapon data
	if weapon_data == null:
		cached_damage = 15
		cached_cooldown = 1.2
		cached_knockback = 200.0


func _process(delta: float) -> void:
	super._process(delta)

	# Update visual rotation to match aim
	if not is_attacking:
		sweep_visual.rotation = _get_aim_direction().angle()

# =============================================================================
# SETUP
# =============================================================================

func _setup_sweep_area() -> void:
	if sweep_area:
		sweep_area.area_entered.connect(_on_sweep_area_entered)
		sweep_area.monitoring = false  # Only enable during attack

# =============================================================================
# ATTACK
# =============================================================================

func _fire() -> void:
	if is_attacking:
		return

	attack_direction = _get_aim_direction()
	enemies_hit.clear()

	# Enable hitbox
	is_attacking = true
	sweep_area.monitoring = true

	# Position and rotate sweep
	sweep_visual.rotation = attack_direction.angle()

	# Play sweep animation
	_play_sweep_animation()

	# Sound effect
	EventBus.sfx_requested.emit("sword_swing")

	# Start cooldown after attack
	super._fire()

	# Disable hitbox after duration
	get_tree().create_timer(SWEEP_DURATION).timeout.connect(_end_attack)


func _end_attack() -> void:
	is_attacking = false
	sweep_area.monitoring = false


func _play_sweep_animation() -> void:
	# Rotate the visual through the arc
	var start_angle := attack_direction.angle() - deg_to_rad(SWEEP_ARC / 2)
	var end_angle := attack_direction.angle() + deg_to_rad(SWEEP_ARC / 2)

	sweep_visual.rotation = start_angle
	sweep_visual.modulate.a = 1.0
	sweep_visual.scale = Vector2(cached_area, cached_area)

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(sweep_visual, "rotation", end_angle, SWEEP_DURATION)
	tween.tween_property(sweep_visual, "modulate:a", 0.0, SWEEP_DURATION)

# =============================================================================
# COLLISION
# =============================================================================

func _on_sweep_area_entered(area: Area2D) -> void:
	if not is_attacking:
		return

	# Check if it's an enemy hurtbox
	if not area is HurtboxComponent:
		return

	var hurtbox := area as HurtboxComponent
	if hurtbox.owner_entity == null:
		return

	# Don't hit same enemy twice per swing
	if hurtbox.owner_entity in enemies_hit:
		return

	enemies_hit.append(hurtbox.owner_entity)

	# Calculate damage with crit
	var final_damage := cached_damage
	var is_crit := false

	if stats_component and stats_component.roll_crit():
		final_damage = int(final_damage * stats_component.get_crit_damage())
		is_crit = true

	# Calculate knockback
	var knockback_dir: Vector2 = (hurtbox.owner_entity.global_position - owner_entity.global_position).normalized()
	var knockback_force: Vector2 = knockback_dir * cached_knockback

	# Apply hit
	hurtbox.receive_hit(null, final_damage, knockback_force, is_crit)
