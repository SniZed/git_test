extends Node
## Top-level game flow (deliverable B). Owns the high-level state and scene swaps.
## Fas 1 flow: BOOT -> IN_RAID -> RAID_RESULT -> (restart) BOOT.
## The hub (Fas 2) slots in between RAID_RESULT and the next raid.

enum GameState { BOOT, IN_RAID, RAID_RESULT }
enum RunResult { EXTRACTED, DIED, ABORTED }

const RAID_SCENE := "res://scenes/raid/raid.tscn"
const MAIN_SCENE := "res://scenes/boot/main.tscn"

var state: int = GameState.BOOT

func _ready() -> void:
	EventBus.run_ended.connect(_on_run_ended)

func start_raid(vault: VaultData) -> void:
	_set_state(GameState.IN_RAID)
	RunManager.begin_run(vault)
	get_tree().paused = false
	get_tree().change_scene_to_file(RAID_SCENE)

func _on_run_ended(_result: int) -> void:
	_set_state(GameState.RAID_RESULT)

func restart() -> void:
	_set_state(GameState.BOOT)
	get_tree().paused = false
	get_tree().change_scene_to_file(MAIN_SCENE)

func _set_state(new_state: int) -> void:
	var old := state
	state = new_state
	EventBus.game_state_changed.emit(old, new_state)
