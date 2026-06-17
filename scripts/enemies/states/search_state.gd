class_name SearchState
extends State
## Investigate: move to the last known position / heard noise. Re-acquire the
## player on sight (-> Chase) or give up and return to Patrol.

var _time: float = 0.0

func enter(_msg: Dictionary = {}) -> void:
	_time = 0.0

func physics_update(delta: float) -> void:
	var e = machine.owner_node
	if e.can_see_player():
		e.last_known_pos = e.player.global_position
		machine.change_state("Chase")
		return
	e.move_toward_point(e.last_known_pos, delta)
	_time += delta
	if e.global_position.distance_to(e.last_known_pos) < 12.0 or _time > 4.0:
		machine.change_state("Patrol")
