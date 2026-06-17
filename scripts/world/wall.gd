class_name Wall
extends StaticBody2D
## Simple rectangular wall (world layer 1). Blocks movement and line of sight.
## Set `size` before adding to the tree.

@export var size: Vector2 = Vector2(64, 64)
var color: Color = Color(0.22, 0.22, 0.28)

func _ready() -> void:
	collision_layer = 1
	collision_mask = 0
	var cs := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	cs.shape = rect
	add_child(cs)
	queue_redraw()

func _draw() -> void:
	draw_rect(Rect2(-size / 2.0, size), color)
