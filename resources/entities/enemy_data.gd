class_name EnemyData
extends Resource
## Data-driven enemy archetype. Drives Enemy (scripts/enemies/enemy.gd).

@export var id: StringName = &""
@export var display_name: String = "Enemy"

@export_group("Stats")
@export var max_hp: float = 45.0
@export var move_speed: float = 95.0
@export var damage: float = 9.0

@export_group("Combat")
@export var attack_range: float = 340.0
@export var fire_rate: float = 1.6           ## shots per second when in combat

@export_group("Perception")
@export var hearing_radius: float = 280.0
@export var sight_range: float = 380.0

@export_group("Rewards")
@export var xp_value: int = 12
@export var loot_drop_chance: float = 0.5
@export var loot_item: ItemData

@export_group("Visual")
@export var color: Color = Color(0.85, 0.32, 0.32)
