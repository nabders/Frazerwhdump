## LevelUpUI - Displays upgrade choices when player levels up
## Shows 3-4 choices, player selects with 1-4 keys or clicks
class_name LevelUpUI
extends CanvasLayer

# =============================================================================
# SIGNALS
# =============================================================================

signal choice_made(choice_index: int)

# =============================================================================
# CONSTANTS
# =============================================================================

const MAX_CHOICES: int = 4
const CHOICE_COLORS: Array[Color] = [
	Color(0.4, 0.6, 1.0),   # Blue
	Color(0.4, 1.0, 0.5),   # Green
	Color(1.0, 0.8, 0.3),   # Gold
	Color(1.0, 0.5, 0.8)    # Pink
]

# =============================================================================
# NODES
# =============================================================================

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var choices_container: VBoxContainer = $Panel/VBoxContainer/ChoicesContainer
@onready var instruction_label: Label = $Panel/VBoxContainer/InstructionLabel

# =============================================================================
# STATE
# =============================================================================

var current_choices: Array = []
var choice_buttons: Array[Button] = []
var is_active: bool = false

# =============================================================================
# LIFECYCLE
# =============================================================================

func _ready() -> void:
	layer = 20
	visible = false
	_connect_signals()
	_create_choice_buttons()


func _unhandled_input(event: InputEvent) -> void:
	if not is_active:
		return

	# Number key selection
	for i in range(1, MAX_CHOICES + 1):
		if event.is_action_pressed("select_%d" % i):
			if i <= current_choices.size():
				_select_choice(i - 1)
				get_viewport().set_input_as_handled()
				return

# =============================================================================
# SETUP
# =============================================================================

func _connect_signals() -> void:
	EventBus.show_level_up_choices.connect(_on_show_choices)
	EventBus.player_leveled_up.connect(_on_player_leveled_up)


func _create_choice_buttons() -> void:
	# Clear existing
	for child in choices_container.get_children():
		child.queue_free()
	choice_buttons.clear()

	# Create button for each possible choice
	for i in MAX_CHOICES:
		var button := Button.new()
		button.name = "Choice%d" % (i + 1)
		button.custom_minimum_size = Vector2(400, 80)
		button.pressed.connect(_on_choice_button_pressed.bind(i))
		choices_container.add_child(button)
		choice_buttons.append(button)
		button.visible = false

# =============================================================================
# DISPLAY
# =============================================================================

func show_choices(choices: Array) -> void:
	current_choices = choices
	is_active = true
	visible = true

	# Update title
	title_label.text = "LEVEL UP! (Lv.%d)" % GameManager.current_level

	# Update buttons
	for i in MAX_CHOICES:
		var button := choice_buttons[i]
		if i < choices.size():
			var choice: Dictionary = choices[i]
			button.visible = true
			button.text = "[%d] %s\n%s" % [i + 1, choice.name, choice.description]
			button.modulate = CHOICE_COLORS[i]

			# Add icon indicator for type
			var type_prefix := ""
			match choice.type:
				"weapon":
					type_prefix = "[WEAPON] "
				"item":
					type_prefix = "[ITEM] "
				"upgrade":
					type_prefix = "[UPGRADE] "
			button.text = "[%d] %s%s\n%s" % [i + 1, type_prefix, choice.name, choice.description]
		else:
			button.visible = false

	instruction_label.text = "Press 1-%d to select" % choices.size()


func hide_choices() -> void:
	is_active = false
	visible = false
	current_choices.clear()

# =============================================================================
# SELECTION
# =============================================================================

func _select_choice(index: int) -> void:
	if index < 0 or index >= current_choices.size():
		return

	var choice: Dictionary = current_choices[index]

	# Apply the choice
	_apply_choice(choice)

	# Emit signal
	choice_made.emit(index)
	EventBus.level_up_choice_selected.emit(index)

	# Hide UI
	hide_choices()


func _apply_choice(choice: Dictionary) -> void:
	var player := GameManager.get_player()
	if player == null:
		return

	match choice.type:
		"weapon":
			if player.weapon_manager:
				player.weapon_manager.add_weapon(choice.id)
		"item":
			# Items would be handled by an item manager
			_apply_item(choice, player)
		"upgrade":
			_apply_stat_upgrade(choice, player)


func _apply_item(choice: Dictionary, player: Player) -> void:
	# Apply stat modifiers from item
	if "modifiers" in choice:
		for stat_name in choice.modifiers:
			var mod: Dictionary = choice.modifiers[stat_name]
			player.stats_component.add_modifier(stat_name, "item_%s" % choice.id, mod.type, mod.value)


func _apply_stat_upgrade(choice: Dictionary, player: Player) -> void:
	if "stat" in choice and "value" in choice:
		player.stats_component.add_modifier(
			choice.stat,
			"upgrade_%s_%d" % [choice.stat, GameManager.current_level],
			choice.get("modifier_type", "add"),
			choice.value
		)

# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

func _on_show_choices(choices: Array) -> void:
	show_choices(choices)


func _on_player_leveled_up(new_level: int) -> void:
	# Generate choices and show UI
	var choices := _generate_choices()
	show_choices(choices)


func _on_choice_button_pressed(index: int) -> void:
	_select_choice(index)

# =============================================================================
# CHOICE GENERATION
# =============================================================================

func _generate_choices() -> Array:
	var choices: Array = []
	var player := GameManager.get_player()

	# Get available options
	var available_weapons := _get_available_weapons(player)
	var available_items := _get_available_items()
	var available_upgrades := _get_stat_upgrades()

	# Combine all options
	var all_options: Array = []
	all_options.append_array(available_weapons)
	all_options.append_array(available_items)
	all_options.append_array(available_upgrades)

	# Shuffle and pick 3-4
	all_options.shuffle()
	var num_choices := mini(randi_range(3, 4), all_options.size())

	for i in num_choices:
		choices.append(all_options[i])

	# Ensure at least one choice
	if choices.is_empty():
		choices.append(_get_fallback_choice())

	return choices


func _get_available_weapons(player: Player) -> Array:
	var weapons: Array = []

	# New weapons player doesn't have
	var weapon_pool := ["magic_wand", "orbiting_skulls"]

	for weapon_id in weapon_pool:
		if player.weapon_manager == null or not player.weapon_manager.has_weapon(weapon_id):
			weapons.append({
				"type": "weapon",
				"id": weapon_id,
				"name": _get_weapon_name(weapon_id),
				"description": _get_weapon_description(weapon_id)
			})
		elif not player.weapon_manager.get_weapon_by_id(weapon_id).is_max_level():
			# Offer upgrade for existing weapon
			var current_level: int = player.weapon_manager.get_weapon_by_id(weapon_id).current_level
			weapons.append({
				"type": "weapon",
				"id": weapon_id,
				"name": _get_weapon_name(weapon_id) + " (Lv.%d → %d)" % [current_level, current_level + 1],
				"description": "+Damage, -Cooldown"
			})

	# Always offer rusty sword upgrade if not max
	if player.weapon_manager and player.weapon_manager.has_weapon("rusty_sword"):
		var sword = player.weapon_manager.get_weapon_by_id("rusty_sword")
		if not sword.is_max_level():
			weapons.append({
				"type": "weapon",
				"id": "rusty_sword",
				"name": "Rusty Sword (Lv.%d → %d)" % [sword.current_level, sword.current_level + 1],
				"description": "+Damage, +Area"
			})

	return weapons


func _get_available_items() -> Array:
	return [
		{
			"type": "item",
			"id": "whetstone",
			"name": "Whetstone",
			"description": "+15% Damage",
			"modifiers": {"damage": {"type": "mult", "value": 1.15}}
		},
		{
			"type": "item",
			"id": "running_shoes",
			"name": "Running Shoes",
			"description": "+10% Move Speed",
			"modifiers": {"move_speed": {"type": "mult", "value": 1.10}}
		},
		{
			"type": "item",
			"id": "hollow_heart",
			"name": "Hollow Heart",
			"description": "+20 Max HP",
			"modifiers": {"max_health": {"type": "add", "value": 20}}
		},
		{
			"type": "item",
			"id": "magnet",
			"name": "Magnet",
			"description": "+30% Pickup Radius",
			"modifiers": {"pickup_radius": {"type": "mult", "value": 1.30}}
		},
		{
			"type": "item",
			"id": "crown",
			"name": "Crown",
			"description": "+10% XP Gain",
			"modifiers": {"xp_gain": {"type": "mult", "value": 1.10}}
		}
	]


func _get_stat_upgrades() -> Array:
	return [
		{
			"type": "upgrade",
			"id": "hp_up",
			"name": "+10 Max HP",
			"description": "Increases maximum health",
			"stat": "max_health",
			"value": 10,
			"modifier_type": "add"
		},
		{
			"type": "upgrade",
			"id": "speed_up",
			"name": "+5% Speed",
			"description": "Move faster",
			"stat": "move_speed",
			"value": 1.05,
			"modifier_type": "mult"
		},
		{
			"type": "upgrade",
			"id": "damage_up",
			"name": "+10% Damage",
			"description": "Deal more damage",
			"stat": "damage",
			"value": 1.10,
			"modifier_type": "mult"
		}
	]


func _get_fallback_choice() -> Dictionary:
	return {
		"type": "upgrade",
		"id": "hp_small",
		"name": "+5 Max HP",
		"description": "A small health boost",
		"stat": "max_health",
		"value": 5,
		"modifier_type": "add"
	}


func _get_weapon_name(id: String) -> String:
	match id:
		"rusty_sword": return "Rusty Sword"
		"magic_wand": return "Magic Wand"
		"orbiting_skulls": return "Orbiting Skulls"
	return id.capitalize()


func _get_weapon_description(id: String) -> String:
	match id:
		"rusty_sword": return "Melee sweep attack"
		"magic_wand": return "Fires magic projectiles at enemies"
		"orbiting_skulls": return "Skulls orbit around you"
	return "A mysterious weapon"
