## PlayerDodge - Player dodge roll state
extends State

var player: Player


func enter(msg: Dictionary = {}) -> void:
	super.enter(msg)
	player = entity as Player

	# Lock normal movement input during dodge
	if player and player.movement_component:
		player.movement_component.lock_movement()


func exit() -> void:
	# Unlock movement when exiting dodge
	if player and player.movement_component:
		player.movement_component.unlock_movement()


func update(delta: float) -> void:
	super.update(delta)
	# Dodge duration is handled by timer in player script


func physics_update(delta: float) -> void:
	if player == null:
		return

	# Continue moving in dodge direction
	# Speed boost is handled by player script
	if player.is_dodging:
		player.movement_component.set_movement_direction(player.dodge_direction)
