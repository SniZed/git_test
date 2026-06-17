class_name State
extends Node
## Base state for the generic FSM (deliverable D). Subclasses override the hooks.
## `machine.owner_node` is the actor that owns this FSM (e.g. the Enemy).

var machine: StateMachine

func enter(_msg: Dictionary = {}) -> void:
	pass

func exit() -> void:
	pass

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	pass
