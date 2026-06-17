class_name Enemy
extends CharacterBody2D
## Data-driven enemy (deliverable C/D). Behaviour runs on the generic node-based
## StateMachine with Patrol / Chase / Search states (Fas 1 subset of the full
## patrol→investigate→alert→combat→search machine). Built in code.

var data: EnemyData
var hp: float
var player: Node2D
var last_known_pos: Vector2 = Vector2.ZERO
var machine: StateMachine

var _fire_cd: float = 0.0

func setup(enemy_data: EnemyData) -> void:
	data = enemy_data

func _ready() -> void:
	add_to_group("enemies")
	if data == null:
		data = load("res://data/enemies/guard.tres")
	hp = data.max_hp

	collision_layer = 4
	collision_mask = 1 | 2  # walls + player

	var cs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 13.0
	cs.shape = circle
	add_child(cs)

	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		player = players[0]

	machine = StateMachine.new()
	machine.name = "StateMachine"
	machine.initial_state = "Patrol"
	var patrol := PatrolState.new(); patrol.name = "Patrol"
	var chase := ChaseState.new(); chase.name = "Chase"
	var search := SearchState.new(); search.name = "Search"
	machine.add_child(patrol)
	machine.add_child(chase)
	machine.add_child(search)
	add_child(machine)
	machine.setup(self)

	EventBus.noise_emitted.connect(_on_noise)
	queue_redraw()

func _on_noise(pos: Vector2, radius: float, source) -> void:
	if source == self or data == null:
		return
	if global_position.distance_to(pos) <= radius:
		last_known_pos = pos
		if machine and machine.current_name() != "Chase":
			machine.change_state("Search")

func can_see_player() -> bool:
	if player == null:
		return false
	var d := global_position.distance_to(player.global_position)
	if d > data.sight_range:
		return false
	var space := get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(global_position, player.global_position, 1)
	var hit := space.intersect_ray(q)
	return hit.is_empty()  # nothing on the world layer blocks the line

func move_toward_point(point: Vector2, _delta: float) -> void:
	var to := point - global_position
	if to.length() < 6.0:
		velocity = Vector2.ZERO
	else:
		velocity = to.normalized() * data.move_speed
	move_and_slide()

func try_shoot(delta: float) -> void:
	_fire_cd -= delta
	if _fire_cd > 0.0 or player == null:
		return
	_fire_cd = 1.0 / max(data.fire_rate, 0.1)
	var dir := (player.global_position - global_position).normalized()
	var p := Projectile.new()
	p.setup(dir, 520.0, data.damage, Color(1, 0.45, 0.2), false)
	get_tree().current_scene.add_child(p)
	p.global_position = global_position + dir * 18.0
	EventBus.noise_emitted.emit(global_position, 200.0, self)

func take_damage(amount: float, _source) -> void:
	hp -= amount
	if player:
		last_known_pos = player.global_position
	if machine and machine.current_name() != "Chase":
		machine.change_state("Chase")
	if hp <= 0.0:
		_die()

func _die() -> void:
	EventBus.enemy_died.emit(data, global_position)
	if data.loot_item and randf() < data.loot_drop_chance:
		var lp := LootPickup.new()
		lp.item = data.loot_item
		lp.position = global_position
		get_tree().current_scene.call_deferred("add_child", lp)
	queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 13.0, data.color if data else Color.RED)
