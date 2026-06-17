class_name ItemData
extends Resource
## Base class for all lootable / carryable items.
## Instances live as .tres files under res://data/ — never hardcoded.

@export var id: StringName = &""
@export var display_name: String = "Item"
@export_multiline var description: String = ""
@export_enum("Common", "Uncommon", "Rare", "Epic", "Legendary", "Echo") var rarity: int = 0
@export var base_value: int = 0          ## sell value / economy
@export var weight: float = 1.0          ## counts against carry capacity (Fas 2+)
@export var color: Color = Color.WHITE   ## placeholder visual until art exists
