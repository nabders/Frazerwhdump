## PlayerDead - Player death state
extends State

var player: Player
var death_animation_played: bool = false


func enter(msg: Dictionary = {}) -> void:
	super.enter(msg)
	player = entity as Player
	death_animation_played = false

	if player:
		# Stop all movement
		player.movement_component.stop()
		player.movement_component.lock_movement()

		# Disable collision
		player.set_collision_layer_value(1, false)
		player.hurtbox_area.deactivate()

		# Visual death effect
		_play_death_effect()


func exit() -> void:
	if player:
		# Re-enable if reviving
		player.set_collision_layer_value(1, true)
		player.hurtbox_area.activate()
		player.movement_component.unlock_movement()


func update(delta: float) -> void:
	super.update(delta)

	# Stay in dead state - revival is handled by health component


func _play_death_effect() -> void:
	if player == null:
		return

	# Fade out and shrink
	var tween := player.create_tween()
	tween.set_parallel(true)
	tween.tween_property(player.sprite, "modulate:a", 0.3, 0.5)
	tween.tween_property(player.sprite, "scale", Vector2(0.3, 0.3), 0.5)
	tween.tween_property(player.sprite, "rotation", PI, 0.5)

	death_animation_played = true
