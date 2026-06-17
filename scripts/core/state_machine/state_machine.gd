class_name StateMachine
extends Node
## Generic, reusable FSM (deliverable D). State nodes are added as children;
## call setup(owner) once they exist. Player uses a lightweight enum FSM for
## snappy input; Enemy/Boss use this node-based machine.

@export var initial_state: String = ""

var owner_node: Node
var current: State
var states: Dictionary = {}

func setup(owner_ref: Node) -> void:
	owner_node = owner_ref
	for child in get_children():
		if child is State:
			# Normalise to String so lookups by string literal always match.
			states[String(child.name)] = child
			child.machine = self
	if initial_state == "" and not states.is_empty():
		initial_state = states.keys()[0]
	if states.has(initial_state):
		current = states[initial_state]
		current.enter()

func change_state(state_name: String, msg: Dictionary = {}) -> void:
	if not states.has(state_name) or states[state_name] == current:
		return
	if current:
		current.exit()
	current = states[state_name]
	current.enter(msg)

func current_name() -> String:
	return String(current.name) if current else ""

func _process(delta: float) -> void:
	if current:
		current.update(delta)

func _physics_process(delta: float) -> void:
	if current:
		current.physics_update(delta)
