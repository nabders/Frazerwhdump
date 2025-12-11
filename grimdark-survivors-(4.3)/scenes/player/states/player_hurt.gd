## PlayerHurt - Player taking damage state (brief stagger)
extends State

const HURT_DURATION: float = 0.15

var player: Player


func enter(msg: Dictionary = {}) -> void:
	super.enter(msg)
	player = entity as Player

	# Brief movement lock during hit stagger
	if player and player.movement_component:
		player.movement_component.lock_movement()


func exit() -> void:
	if player and player.movement_component:
		player.movement_component.unlock_movement()


func update(delta: float) -> void:
	super.update(delta)

	# Return to appropriate state after hurt duration
	if time_in_state >= HURT_DURATION:
		if InputManager.is_moving():
			transition_to("Move")
		else:
			transition_to("Idle")


func physics_update(delta: float) -> void:
	pass
