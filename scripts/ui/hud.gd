class_name HUD
extends CanvasLayer
## Minimal in-raid HUD: timer, HP, ammo, loot count, alarm flag, and a result
## overlay. Built in code. Listens to EventBus / polls RunManager + player.

var _info: Label
var _hint: Label
var _result: Label
var _ended: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS  # keep running while the tree is paused

	_info = Label.new()
	_info.position = Vector2(16, 12)
	_info.add_theme_font_size_override("font_size", 18)
	add_child(_info)

	_hint = Label.new()
	_hint.position = Vector2(16, 140)
	_hint.add_theme_font_size_override("font_size", 13)
	_hint.modulate = Color(1, 1, 1, 0.6)
	_hint.text = "WASD move · Shift sprint · Space dodge · LMB fire · R reload\nGrab loot, reach the green pad and hold to EXTRACT."
	add_child(_hint)

	_result = Label.new()
	_result.add_theme_font_size_override("font_size", 40)
	_result.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_result.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_result.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_result.visible = false
	add_child(_result)

	EventBus.run_ended.connect(_on_run_ended)

func _process(_delta: float) -> void:
	if _ended:
		if Input.is_action_just_pressed("ui_accept"):
			GameManager.restart()
		return

	var lines: Array[String] = []
	lines.append("TIME  %5.1f" % RunManager.time_left)
	if RunManager.alarm_active:
		lines.append("** ALARM — enemies hunting **")

	var players := get_tree().get_nodes_in_group("player")
	if players.size() > 0:
		var p: Player = players[0]
		lines.append("HP    %d" % int(max(p.hp, 0.0)))
		if p.weapon:
			var reloading := "  (reloading)" if p.weapon.is_reloading() else ""
			lines.append("AMMO  %d / %d%s" % [p.weapon.ammo_in_mag, p.weapon.data.mag_size, reloading])
	lines.append("LOOT  %d" % RunManager.collected_loot.size())
	_info.text = "\n".join(lines)

func _on_run_ended(result: int) -> void:
	_ended = true
	_hint.visible = false
	_result.visible = true
	get_tree().paused = true
	var header := "EXTRACTED" if result == GameManager.RunResult.EXTRACTED else "YOU DIED"
	var loot_line := "Loot secured: %d" % RunManager.collected_loot.size()
	if result != GameManager.RunResult.EXTRACTED:
		loot_line = "Loot lost: %d" % RunManager.collected_loot.size()
	_result.text = "%s\n\n%s\n\nPress ENTER to return to hub" % [header, loot_line]
