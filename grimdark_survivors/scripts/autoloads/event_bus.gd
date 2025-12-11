## EventBus - Central signal hub for game-wide events
## All game events should go through this autoload for loose coupling
extends Node

# =============================================================================
# PLAYER SIGNALS
# =============================================================================

## Emitted when player takes damage
signal player_damaged(amount: int, source: Node)

## Emitted when player dies
signal player_died

## Emitted when player health changes
signal player_health_changed(current: int, maximum: int)

## Emitted when player gains XP
signal xp_gained(amount: int)

## Emitted when player levels up
signal player_leveled_up(new_level: int)

## Emitted when player picks up an item
signal item_picked_up(item_data: Resource)

## Emitted when player dodges
signal player_dodged

## Emitted when player position updates (for enemies to track)
signal player_position_updated(position: Vector2)

# =============================================================================
# ENEMY SIGNALS
# =============================================================================

## Emitted when any enemy is killed
signal enemy_killed(enemy: Node, position: Vector2, xp_value: int)

## Emitted when any enemy takes damage
signal enemy_damaged(enemy: Node, amount: int, source: Node)

## Emitted when an enemy spawns
signal enemy_spawned(enemy: Node)

## Emitted when a boss spawns
signal boss_spawned(boss: Node)

## Emitted when a boss is defeated
signal boss_defeated(boss: Node)

# =============================================================================
# COMBAT SIGNALS
# =============================================================================

## Emitted when damage is dealt (for damage numbers, etc.)
signal damage_dealt(amount: int, position: Vector2, is_crit: bool)

## Emitted when a hitbox connects with a hurtbox
signal hit_registered(attacker: Node, victim: Node, damage: int)

## Emitted when knockback is applied
signal knockback_applied(target: Node, direction: Vector2, force: float)

# =============================================================================
# WEAPON SIGNALS
# =============================================================================

## Emitted when a weapon is acquired
signal weapon_acquired(weapon_data: Resource)

## Emitted when a weapon levels up
signal weapon_leveled_up(weapon_data: Resource, new_level: int)

## Emitted when a weapon evolves
signal weapon_evolved(base_weapon: Resource, evolved_weapon: Resource)

## Emitted when a weapon fires/attacks
signal weapon_fired(weapon: Node)

# =============================================================================
# PICKUP SIGNALS
# =============================================================================

## Emitted when XP gem is collected
signal xp_gem_collected(value: int)

## Emitted when gold is collected
signal gold_collected(amount: int)

## Emitted when a chest is opened
signal chest_opened(chest: Node)

## Emitted when food/health pickup is collected
signal health_pickup_collected(amount: int)

# =============================================================================
# GAME STATE SIGNALS
# =============================================================================

## Emitted when game state changes
signal game_state_changed(old_state: int, new_state: int)

## Emitted when a run starts
signal run_started

## Emitted when a run ends (victory or defeat)
signal run_ended(victory: bool, stats: Dictionary)

## Emitted when game is paused
signal game_paused

## Emitted when game is unpaused
signal game_unpaused

## Emitted every in-game minute for wave management
signal minute_passed(minute: int)

# =============================================================================
# UI SIGNALS
# =============================================================================

## Emitted when level up choices should be displayed
signal show_level_up_choices(choices: Array)

## Emitted when a level up choice is selected
signal level_up_choice_selected(choice_index: int)

## Emitted when the pause menu should be shown
signal show_pause_menu

## Emitted when the pause menu should be hidden
signal hide_pause_menu

## Emitted when a notification should be displayed
signal show_notification(text: String, duration: float)

## Emitted when screen shake should occur
signal screen_shake_requested(intensity: float, duration: float)

# =============================================================================
# META PROGRESSION SIGNALS
# =============================================================================

## Emitted when an achievement is unlocked
signal achievement_unlocked(achievement_id: String)

## Emitted when a character is unlocked
signal character_unlocked(character_id: String)

## Emitted when gold total changes (meta gold, not run gold)
signal meta_gold_changed(new_total: int)

## Emitted when a permanent upgrade is purchased
signal upgrade_purchased(upgrade_id: String, new_level: int)

# =============================================================================
# AUDIO SIGNALS
# =============================================================================

## Emitted to request a sound effect
signal sfx_requested(sfx_name: String)

## Emitted to request music change
signal music_requested(music_name: String, fade_time: float)

## Emitted to stop all audio
signal audio_stop_all


func _ready() -> void:
	print("[EventBus] Initialized - Central signal hub ready")
