## OrbitingSkulls - Skulls that orbit around the player
class_name OrbitingSkulls
extends WeaponBase

# =============================================================================
# CONSTANTS
# =============================================================================

const BASE_ORBIT_RADIUS: float = 80.0
const BASE_ORBIT_SPEED: float = 2.0  # Radians per second
const BASE_SKULL_COUNT: int = 3

# =============================================================================
# STATE
# =============================================================================

var skulls: Array[Node2D] = []
var current_angle: float = 0.0
var orbit_radius: float = BASE_ORBIT_RADIUS
var orbit_speed: float = BASE_ORBIT_SPEED
var skull_count: int = BASE_SKULL_COUNT

# Damage cooldown per skull
var skull_cooldowns: Dictionary = {}
const SKULL_HIT_COOLDOWN: float = 0.5

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	super._ready()

	if weapon_data == null:
		cached_damage = 12
		cached_cooldown = 0.0  # Passive weapon, no cooldown
		cached_area = 1.0

	call_deferred("_create_skulls")


func _process(delta: float) -> void:
	# Don't call super - we don't use the normal firing system
	_update_orbit(delta)
	_update_skull_cooldowns(delta)


func _update_orbit(delta: float) -> void:
	current_angle += orbit_speed * delta

	for i in skulls.size():
		var skull: Node2D = skulls[i]
		var angle: float = current_angle + (TAU / float(skulls.size())) * i
		var offset: Vector2 = Vector2(cos(angle), sin(angle)) * orbit_radius * cached_area
		skull.position = offset
		skull.rotation = angle + PI / 2

# =============================================================================
# SKULL MANAGEMENT
# =============================================================================

func _create_skulls() -> void:
	# Clear existing
	for skull in skulls:
		skull.queue_free()
	skulls.clear()
	skull_cooldowns.clear()

	# Calculate skull count based on level
	skull_count = BASE_SKULL_COUNT + int((current_level - 1) / 2)

	# Create skulls
	for i in skull_count:
		var skull := _create_skull_node()
		skull.name = "Skull_%d" % i
		add_child(skull)
		skulls.append(skull)
		skull_cooldowns[i] = 0.0


func _create_skull_node() -> Area2D:
	var skull := Area2D.new()

	# Collision
	skull.collision_layer = 4  # Player hitbox
	skull.collision_mask = 8   # Enemy hurtbox

	var shape := CircleShape2D.new()
	shape.radius = 15.0
	var collision := CollisionShape2D.new()
	collision.shape = shape
	skull.add_child(collision)

	# Visual
	var sprite := Sprite2D.new()
	var img := Image.create(32, 32, false, Image.FORMAT_RGBA8)

	# Draw skull shape
	for x in 32:
		for y in 32:
			var center := Vector2(16, 16)
			var pos := Vector2(x, y)

			# Head
			if pos.distance_to(center) < 12:
				img.set_pixel(x, y, Color(0.9, 0.9, 0.85))

			# Eyes
			if pos.distance_to(Vector2(12, 14)) < 3 or pos.distance_to(Vector2(20, 14)) < 3:
				img.set_pixel(x, y, Color(0.1, 0.1, 0.1))

			# Nose
			if pos.distance_to(Vector2(16, 18)) < 2:
				img.set_pixel(x, y, Color(0.2, 0.2, 0.2))

			# Mouth
			if y == 22 and abs(x - 16) < 5:
				img.set_pixel(x, y, Color(0.1, 0.1, 0.1))

	sprite.texture = ImageTexture.create_from_image(img)
	skull.add_child(sprite)

	# Connect hit detection
	skull.area_entered.connect(_on_skull_hit.bind(skulls.size()))

	return skull


func _update_skull_cooldowns(delta: float) -> void:
	for i in skull_cooldowns:
		if skull_cooldowns[i] > 0:
			skull_cooldowns[i] -= delta

# =============================================================================
# COLLISION
# =============================================================================

func _on_skull_hit(area: Area2D, skull_index: int) -> void:
	if not area is HurtboxComponent:
		return

	# Check cooldown
	if skull_cooldowns.get(skull_index, 0.0) > 0:
		return

	var hurtbox := area as HurtboxComponent
	if hurtbox.owner_entity == null:
		return

	# Apply damage
	var kb_dir := Vector2.ZERO
	if owner_entity:
		kb_dir = (hurtbox.owner_entity.global_position - owner_entity.global_position).normalized()

	hurtbox.receive_hit(null, cached_damage, kb_dir * cached_knockback, false)

	# Set cooldown for this skull
	skull_cooldowns[skull_index] = SKULL_HIT_COOLDOWN

# =============================================================================
# LEVELING
# =============================================================================

func level_up() -> bool:
	var result := super.level_up()
	if result:
		_create_skulls()  # Recreate with new count
		orbit_speed = BASE_ORBIT_SPEED * (1.0 + current_level * 0.1)
	return result
