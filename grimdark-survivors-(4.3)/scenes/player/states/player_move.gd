## PlayerMove - Player walking/running state
extends State

var player: Player


func enter(msg: Dictionary = {}) -> void:
	super.enter(msg)
	player = entity as Player


func update(delta: float) -> void:
	super.update(delta)

	# Check for stopping
	if not InputManager.is_moving():
		transition_to("Idle")


func physics_update(delta: float) -> void:
	if player == null:
		return

	# Movement is handled by the player script directly
	# This state is mainly for animation control
	pass
