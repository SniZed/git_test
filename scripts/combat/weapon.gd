class_name Weapon
extends RefCounted
## Runtime weapon state built from a WeaponData resource (deliverable C/D).
## Handles fire-rate cooldown, magazine and reload. Owned by the Player.

var data: WeaponData
var ammo_in_mag: int

var _cooldown: float = 0.0
var _reloading: bool = false
var _reload_left: float = 0.0

func _init(weapon_data: WeaponData) -> void:
	data = weapon_data
	ammo_in_mag = weapon_data.mag_size

func update(delta: float) -> void:
	if _cooldown > 0.0:
		_cooldown -= delta
	if _reloading:
		_reload_left -= delta
		if _reload_left <= 0.0:
			ammo_in_mag = data.mag_size
			_reloading = false

func can_fire() -> bool:
	return not _reloading and _cooldown <= 0.0 and ammo_in_mag > 0

func consume_shot() -> void:
	ammo_in_mag -= 1
	_cooldown = 1.0 / max(data.fire_rate, 0.01)
	if ammo_in_mag <= 0:
		start_reload()

func start_reload() -> void:
	if _reloading or ammo_in_mag == data.mag_size:
		return
	_reloading = true
	_reload_left = data.reload_time

func is_reloading() -> bool:
	return _reloading
