extends Node2D
## Builds and runs one raid (Fas 1). Constructs a static arena, the player,
## enemies from the vault's enemy_pool, loot and an extraction point — all in
## code. The procedural room-graph generator (arch §E) replaces _build_arena()
## in Fas 2.

const WALL := 32.0
const ARENA := Rect2(Vector2(-600, -400), Vector2(1200, 800))

var player: Player

func _ready() -> void:
	_build_arena()
	_spawn_player()
	_spawn_enemies()
	_spawn_loot()
	_spawn_extraction()
	_add_hud()
	EventBus.timer_expired.connect(_on_alarm)

func _build_arena() -> void:
	# Outer walls (overlap at corners).
	_make_wall(Vector2(ARENA.get_center().x, ARENA.position.y), Vector2(ARENA.size.x + WALL, WALL))
	_make_wall(Vector2(ARENA.get_center().x, ARENA.end.y), Vector2(ARENA.size.x + WALL, WALL))
	_make_wall(Vector2(ARENA.position.x, ARENA.get_center().y), Vector2(WALL, ARENA.size.y + WALL))
	_make_wall(Vector2(ARENA.end.x, ARENA.get_center().y), Vector2(WALL, ARENA.size.y + WALL))
	# Inner cover / sight blockers (give stealth a purpose).
	_make_wall(Vector2(-200, -110), Vector2(180, 40))
	_make_wall(Vector2(220, 120), Vector2(40, 220))
	_make_wall(Vector2(0, 0), Vector2(120, 120))
	_make_wall(Vector2(-300, 220), Vector2(40, 160))

func _make_wall(center: Vector2, size: Vector2) -> void:
	var w := Wall.new()
	w.size = size
	w.position = center
	add_child(w)

func _spawn_player() -> void:
	player = Player.new()
	player.position = Vector2(-460, 300)
	add_child(player)

func _spawn_enemies() -> void:
	var vault := RunManager.current_vault
	var pool: Array = vault.enemy_pool if vault and not vault.enemy_pool.is_empty() else []
	var positions := [
		Vector2(300, -250), Vector2(-320, -260),
		Vector2(420, 220), Vector2(40, -300), Vector2(-150, 250),
	]
	for pos in positions:
		var ed: EnemyData = RNG.pick(pool) if not pool.is_empty() else load("res://data/enemies/guard.tres")
		var e := Enemy.new()
		e.setup(ed)
		e.position = pos
		add_child(e)

func _spawn_loot() -> void:
	var vault := RunManager.current_vault
	var pool: Array = vault.loot_pool if vault and not vault.loot_pool.is_empty() else []
	var positions := [
		Vector2(-200, -260), Vector2(260, -150), Vector2(-380, 120),
		Vector2(460, -250), Vector2(120, 260),
	]
	for pos in positions:
		var lp := LootPickup.new()
		lp.item = RNG.pick(pool) if not pool.is_empty() else load("res://data/items/medkit.tres")
		lp.position = pos
		add_child(lp)

func _spawn_extraction() -> void:
	var ep := ExtractionPoint.new()
	ep.position = Vector2(480, 320)
	add_child(ep)

func _add_hud() -> void:
	add_child(HUD.new())

func _on_alarm() -> void:
	# Timer ran out: every enemy now hunts the player's last position.
	for e in get_tree().get_nodes_in_group("enemies"):
		if e.player:
			e.last_known_pos = e.player.global_position
		if e.machine and e.machine.current_name() != "Chase":
			e.machine.change_state("Search")
