extends Node
## Owns all RUN-ONLY state (deliverable B/G): current vault, the raid timer,
## loot collected this raid, and the equipped loadout. Everything here is
## cleared at raid end and is NEVER written to disk (that's SaveManager's job,
## which arrives with the hub in Fas 2).

var current_vault: VaultData
var run_active: bool = false
var alarm_active: bool = false
var time_left: float = 0.0
var collected_loot: Array = []        ## Array[ItemData] picked up this raid

## Loadout — hardcoded for the slice; chosen in the hub loadout UI in Fas 2.
var equipped_weapon: WeaponData

var _expired: bool = false

func _ready() -> void:
	equipped_weapon = load("res://data/weapons/pistol.tres")
	EventBus.extraction_completed.connect(_on_extraction_completed)
	EventBus.player_died.connect(_on_player_died)

func get_equipped_weapon() -> WeaponData:
	return equipped_weapon

func begin_run(vault: VaultData) -> void:
	current_vault = vault
	run_active = true
	alarm_active = false
	_expired = false
	time_left = vault.raid_time_seconds if vault else 90.0
	collected_loot.clear()
	EventBus.run_started.emit(vault)

func add_loot(item: ItemData) -> void:
	if item == null:
		return
	collected_loot.append(item)
	EventBus.item_picked_up.emit(item)

func end_run(result: int) -> void:
	if not run_active:
		return
	run_active = false
	EventBus.run_ended.emit(result)

func _process(delta: float) -> void:
	if not run_active:
		return
	time_left -= delta
	EventBus.timer_tick.emit(time_left)
	if time_left <= 0.0 and not _expired:
		time_left = 0.0
		_expired = true
		alarm_active = true
		EventBus.timer_expired.emit()
		EventBus.alarm_triggered.emit()

func _on_extraction_completed(_loot: Array) -> void:
	end_run(GameManager.RunResult.EXTRACTED)

func _on_player_died() -> void:
	end_run(GameManager.RunResult.DIED)
