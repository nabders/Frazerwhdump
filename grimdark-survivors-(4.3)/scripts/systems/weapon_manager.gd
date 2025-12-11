## WeaponManager - Manages player's equipped weapons
## Handles adding, removing, and leveling weapons
class_name WeaponManager
extends Node

# =============================================================================
# SIGNALS
# =============================================================================

signal weapon_added(weapon: WeaponBase)
signal weapon_removed(weapon: WeaponBase)
signal weapon_leveled(weapon: WeaponBase, new_level: int)

# =============================================================================
# CONSTANTS
# =============================================================================

const MAX_WEAPONS: int = 6

# =============================================================================
# PRELOADS
# =============================================================================

const WEAPON_SCENES: Dictionary = {
	"rusty_sword": preload("res://scenes/weapons/rusty_sword.tscn"),
	"magic_wand": preload("res://scenes/weapons/magic_wand.tscn"),
	"orbiting_skulls": preload("res://scenes/weapons/orbiting_skulls.tscn"),
}

# =============================================================================
# STATE
# =============================================================================

var weapons: Array[WeaponBase] = []
var owner_entity: Node2D = null

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	owner_entity = get_parent()
	_connect_signals()


func _connect_signals() -> void:
	EventBus.run_started.connect(_on_run_started)

# =============================================================================
# WEAPON MANAGEMENT
# =============================================================================

func add_weapon(weapon_id: String) -> WeaponBase:
	# Check if already have this weapon
	var existing := get_weapon_by_id(weapon_id)
	if existing:
		# Level up instead
		existing.level_up()
		weapon_leveled.emit(existing, existing.current_level)
		return existing

	# Check max weapons
	if weapons.size() >= MAX_WEAPONS:
		push_warning("[WeaponManager] Cannot add weapon, max weapons reached")
		return null

	# Create weapon
	if weapon_id not in WEAPON_SCENES:
		push_error("[WeaponManager] Unknown weapon ID: %s" % weapon_id)
		return null

	var weapon_scene: PackedScene = WEAPON_SCENES[weapon_id]
	var weapon: WeaponBase = weapon_scene.instantiate()
	weapon.name = weapon_id

	add_child(weapon)
	weapons.append(weapon)

	weapon_added.emit(weapon)
	EventBus.weapon_acquired.emit(weapon.weapon_data)

	print("[WeaponManager] Added weapon: %s" % weapon_id)
	return weapon


func add_weapon_instance(weapon: WeaponBase) -> bool:
	if weapons.size() >= MAX_WEAPONS:
		return false

	add_child(weapon)
	weapons.append(weapon)
	weapon_added.emit(weapon)
	return true


func remove_weapon(weapon: WeaponBase) -> void:
	if weapon in weapons:
		weapons.erase(weapon)
		weapon_removed.emit(weapon)
		weapon.queue_free()


func remove_weapon_by_id(weapon_id: String) -> void:
	var weapon := get_weapon_by_id(weapon_id)
	if weapon:
		remove_weapon(weapon)

# =============================================================================
# QUERIES
# =============================================================================

func get_weapon_by_id(weapon_id: String) -> WeaponBase:
	for weapon in weapons:
		if weapon.name == weapon_id:
			return weapon
	return null


func has_weapon(weapon_id: String) -> bool:
	return get_weapon_by_id(weapon_id) != null


func get_weapon_count() -> int:
	return weapons.size()


func get_all_weapons() -> Array[WeaponBase]:
	return weapons.duplicate()


func can_add_weapon() -> bool:
	return weapons.size() < MAX_WEAPONS

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_run_started() -> void:
	# Clear existing weapons
	for weapon in weapons:
		weapon.queue_free()
	weapons.clear()

	# Add starting weapon based on character
	# For now, always give rusty sword
	call_deferred("add_weapon", "rusty_sword")

# =============================================================================
# UTILITY
# =============================================================================

func level_up_random_weapon() -> void:
	if weapons.is_empty():
		return

	var upgradable: Array[WeaponBase] = []
	for weapon in weapons:
		if not weapon.is_max_level():
			upgradable.append(weapon)

	if upgradable.is_empty():
		return

	var weapon: WeaponBase = upgradable.pick_random()
	weapon.level_up()
	weapon_leveled.emit(weapon, weapon.current_level)
