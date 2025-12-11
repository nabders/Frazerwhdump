## MagicWand - Fires magic projectiles at nearest enemy
class_name MagicWand
extends WeaponBase

# =============================================================================
# CONSTANTS
# =============================================================================

const PROJECTILE_SPEED: float = 300.0
const BASE_PROJECTILE_COUNT: int = 1

# =============================================================================
# STATE
# =============================================================================

var projectile_scene: PackedScene = null

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	super._ready()

	# Set default stats
	if weapon_data == null:
		cached_damage = 8
		cached_cooldown = 1.0
		cached_amount = 1
		cached_knockback = 50.0


func _fire() -> void:
	var target := _get_nearest_enemy()
	if target == null:
		return

	var projectile_count := cached_amount + int((current_level - 1) / 3)  # +1 projectile every 3 levels

	for i in projectile_count:
		_spawn_projectile(target, i, projectile_count)

	EventBus.sfx_requested.emit("magic_fire")
	super._fire()


func _can_fire() -> bool:
	if not super._can_fire():
		return false
	return _get_nearest_enemy() != null

# =============================================================================
# PROJECTILES
# =============================================================================

func _spawn_projectile(target: Node2D, index: int, total: int) -> void:
	var projectile := _create_projectile()
	if projectile == null:
		return

	# Position at owner
	projectile.global_position = owner_entity.global_position

	# Calculate direction with spread
	var base_dir := (target.global_position - owner_entity.global_position).normalized()
	var spread_angle := 0.0
	if total > 1:
		spread_angle = deg_to_rad(15.0 * (index - (total - 1) / 2.0))
	var direction := base_dir.rotated(spread_angle)

	# Setup projectile
	projectile.setup(direction, cached_damage, PROJECTILE_SPEED, cached_knockback)

	# Add to scene
	var projectiles_container := _get_projectiles_container()
	if projectiles_container:
		projectiles_container.add_child(projectile)
	else:
		owner_entity.get_parent().add_child(projectile)


func _create_projectile() -> Node2D:
	var projectile := MagicProjectile.new()
	return projectile


func _get_projectiles_container() -> Node2D:
	var main := owner_entity.get_tree().get_first_node_in_group("main")
	if main and main.has_method("get_projectiles_container"):
		return main.get_projectiles_container()
	return null


# =============================================================================
# INNER CLASS: Magic Projectile
# =============================================================================

class MagicProjectile extends Area2D:
	var direction: Vector2 = Vector2.RIGHT
	var speed: float = 300.0
	var damage: int = 10
	var knockback: float = 50.0
	var lifetime: float = 3.0
	var pierce_count: int = 1
	var enemies_hit: Array = []

	func _ready() -> void:
		# Setup collision
		collision_layer = 4  # Player hitbox
		collision_mask = 8   # Enemy hurtbox

		# Create shape
		var shape := CircleShape2D.new()
		shape.radius = 8.0
		var collision := CollisionShape2D.new()
		collision.shape = shape
		add_child(collision)

		# Create visual
		var sprite := Sprite2D.new()
		var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		for x in 16:
			for y in 16:
				var dist := Vector2(x, y).distance_to(Vector2(8, 8))
				if dist < 6:
					var brightness := 1.0 - (dist / 8.0)
					img.set_pixel(x, y, Color(0.5, 0.8, 1.0) * brightness)
		sprite.texture = ImageTexture.create_from_image(img)
		add_child(sprite)

		# Connect signals
		area_entered.connect(_on_area_entered)

		# Auto-destroy after lifetime
		get_tree().create_timer(lifetime).timeout.connect(queue_free)

	func _process(delta: float) -> void:
		position += direction * speed * delta

	func setup(dir: Vector2, dmg: int, spd: float, kb: float) -> void:
		direction = dir.normalized()
		damage = dmg
		speed = spd
		knockback = kb
		rotation = direction.angle()

	func _on_area_entered(area: Area2D) -> void:
		if not area is HurtboxComponent:
			return

		var hurtbox := area as HurtboxComponent
		if hurtbox.owner_entity in enemies_hit:
			return

		enemies_hit.append(hurtbox.owner_entity)

		# Calculate knockback
		var kb_dir := direction
		var kb_force := kb_dir * knockback

		# Apply hit
		hurtbox.receive_hit(null, damage, kb_force, false)

		# Reduce pierce
		pierce_count -= 1
		if pierce_count <= 0:
			queue_free()
