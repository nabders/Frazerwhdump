## PlayerIdle - Player standing still state
extends State

var player: Player


func enter(msg: Dictionary = {}) -> void:
	super.enter(msg)
	player = entity as Player

	if player and player.movement_component:
		player.movement_component.set_movement_direction(Vector2.ZERO)


func update(delta: float) -> void:
	super.update(delta)

	# Check for movement input to transition to Move state
	if InputManager.is_moving():
		transition_to("Move")


func physics_update(delta: float) -> void:
	pass
