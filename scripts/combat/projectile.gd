class_name Projectile
extends Area2D
## Lightweight bullet. Built entirely in code (collision shape + visual) so the
## project needs no fragile hand-authored .tscn for it. Spawned via Projectile.new().
##
## Collision layers used across the project:
##   1 = world/walls   2 = player   4 = enemy   32 = pickups/interactables

var velocity: Vector2 = Vector2.ZERO
var damage: float = 10.0
var lifetime: float = 2.0
var color: Color = Color.YELLOW
var shooter_is_player: bool = true

func setup(dir: Vector2, speed: float, dmg: float, col: Color, from_player: bool) -> void:
	velocity = dir.normalized() * speed
	damage = dmg
	color = col
	shooter_is_player = from_player

func _ready() -> void:
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 4.0
	shape.shape = circle
	add_child(shape)

	collision_layer = 0
	# Player bullets hit walls(1)+enemies(4); enemy bullets hit walls(1)+player(2).
	collision_mask = 1 | (4 if shooter_is_player else 2)
	monitoring = true
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _physics_process(delta: float) -> void:
	position += velocity * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body.has_method("take_damage"):
		body.take_damage(damage, self)
	queue_free()

func _draw() -> void:
	draw_circle(Vector2.ZERO, 4.0, color)
