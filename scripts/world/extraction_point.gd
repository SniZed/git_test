class_name ExtractionPoint
extends Area2D
## Stand in the zone for `extract_time` seconds to extract and bank your loot.
## Leaving resets the channel (extraction risk/reward — deliverable, arch §8).

@export var extract_time: float = 3.0
var radius: float = 50.0

var _player_in: bool = false
var _t: float = 0.0
var _done: bool = false

func _ready() -> void:
	collision_layer = 32
	collision_mask = 2  # detect the player
	monitoring = true
	var cs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = radius
	cs.shape = circle
	add_child(cs)
	body_entered.connect(_on_enter)
	body_exited.connect(_on_exit)
	queue_redraw()

func _on_enter(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in = true
		EventBus.extraction_started.emit(self)

func _on_exit(body: Node) -> void:
	if body.is_in_group("player"):
		_player_in = false
		_t = 0.0
		queue_redraw()

func _process(delta: float) -> void:
	if _done or not _player_in:
		return
	_t += delta
	queue_redraw()
	if _t >= extract_time:
		_done = true
		EventBus.extraction_completed.emit(RunManager.collected_loot)

func _draw() -> void:
	draw_circle(Vector2.ZERO, radius, Color(0.2, 0.8, 0.4, 0.3))
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 48, Color(0.3, 1.0, 0.5, 0.8), 2.0)
	if _player_in:
		var frac: float = clamp(_t / extract_time, 0.0, 1.0)
		draw_arc(Vector2.ZERO, radius + 6.0, -PI / 2.0, -PI / 2.0 + TAU * frac, 48, Color(0.4, 1.0, 0.5), 4.0)
