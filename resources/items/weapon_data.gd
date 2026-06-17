class_name WeaponData
extends ItemData
## Data-driven weapon definition. Runtime behaviour is handled by Weapon (scripts/combat/weapon.gd).

@export_group("Ballistics")
@export var damage: float = 14.0
@export var fire_rate: float = 6.0           ## shots per second
@export var projectile_speed: float = 750.0
@export var spread_degrees: float = 3.0

@export_group("Handling")
@export var mag_size: int = 14
@export var reload_time: float = 1.1

@export_group("Tension Loop")
@export var noise_radius: float = 280.0      ## how far a shot is heard (feeds AlarmManager)

@export_group("Visual")
@export var projectile_color: Color = Color(1, 0.9, 0.3)
