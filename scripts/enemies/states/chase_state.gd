class_name ChaseState
extends State
## Alert + combat: close the distance, shoot inside attack range, give up after
## losing line of sight for a while (-> Search).

var _lost: float = 0.0

func enter(_msg: Dictionary = {}) -> void:
	_lost = 0.0

func physics_update(delta: float) -> void:
	var e = machine.owner_node
	if e.player == null:
		machine.change_state("Patrol")
		return
	if e.can_see_player():
		_lost = 0.0
		e.last_known_pos = e.player.global_position
		var d: float = e.global_position.distance_to(e.player.global_position)
		if d > e.data.attack_range:
			e.move_toward_point(e.player.global_position, delta)
		else:
			e.velocity = Vector2.ZERO
			e.move_and_slide()
			e.try_shoot(delta)
	else:
		_lost += delta
		e.move_toward_point(e.last_known_pos, delta)
		if _lost > 2.5:
			machine.change_state("Search")
