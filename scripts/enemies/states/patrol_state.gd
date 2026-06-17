class_name PatrolState
extends State
## Calm patrol: wander around the spawn point until the player is seen.

var _origin: Vector2
var _target: Vector2
var _wait: float = 0.0
var _has_origin: bool = false

func enter(_msg: Dictionary = {}) -> void:
	var e = machine.owner_node
	if not _has_origin:
		_origin = e.global_position
		_has_origin = true
	_pick_target()

func _pick_target() -> void:
	_target = _origin + Vector2(randf_range(-130.0, 130.0), randf_range(-130.0, 130.0))
	_wait = randf_range(0.6, 1.6)

func physics_update(delta: float) -> void:
	var e = machine.owner_node
	if e.can_see_player():
		e.last_known_pos = e.player.global_position
		machine.change_state("Chase")
		return
	e.move_toward_point(_target, delta)
	if e.global_position.distance_to(_target) < 10.0:
		_wait -= delta
		if _wait <= 0.0:
			_pick_target()
