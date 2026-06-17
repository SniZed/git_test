class_name VaultData
extends Resource
## Defines a vault / raid: timer, which enemies spawn and which loot can drop.
## Procedural layout parameters (room counts, templates) arrive in Fas 2.

@export var id: StringName = &""
@export var display_name: String = "Vault"
@export var raid_time_seconds: float = 75.0  ## global timer; expiry triggers the alarm

## Untyped Arrays keep hand-authored .tres files robust across Godot versions.
@export var enemy_pool: Array = []           ## Array[EnemyData]
@export var loot_pool: Array = []            ## Array[ItemData]
