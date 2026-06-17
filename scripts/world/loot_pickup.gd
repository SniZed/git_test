class_name LootPickup
extends Area2D
## A pickup carrying one ItemData. Picked up on player contact -> RunManager.
## Set `item` before adding to the tree.

var item: ItemData

func _ready() -> void:
	collision_layer = 32
	collision_mask = 2  # detect the player
	monitoring = true
	var cs := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 12.0
	cs.shape = circle
	add_child(cs)
	body_entered.connect(_on_body_entered)
	queue_redraw()

func _on_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		RunManager.add_loot(item)
		queue_free()

func _draw() -> void:
	var col: Color = item.color if item else Color.YELLOW
	draw_rect(Rect2(Vector2(-9, -9), Vector2(18, 18)), col)
	draw_rect(Rect2(Vector2(-9, -9), Vector2(18, 18)), Color.WHITE, false, 1.5)
