extends Node
## Entry point (Fas 1). Loads the vault and drops straight into a raid.
## In Fas 2 this becomes the hub, and the raid is launched from the map terminal.

func _ready() -> void:
	get_tree().paused = false
	var vault: VaultData = load("res://data/vaults/industrial_01.tres")
	GameManager.start_raid(vault)
