extends Node
## Seedable RNG wrapper (autoload). A single source of randomness so a run
## can be reproduced/debugged by reusing its seed — important to wire in early
## (see arch §E), even if Fas 1 only uses it lightly.

var _rng := RandomNumberGenerator.new()
var current_seed: int = 0

func _ready() -> void:
	randomize_seed()

func randomize_seed() -> void:
	_rng.randomize()
	current_seed = _rng.seed

func seed_run(s: int) -> void:
	current_seed = s
	_rng.seed = s

func randf() -> float:
	return _rng.randf()

func randf_range(from: float, to: float) -> float:
	return _rng.randf_range(from, to)

func randi_range(from: int, to: int) -> int:
	return _rng.randi_range(from, to)

func chance(probability: float) -> bool:
	return _rng.randf() < probability

func pick(arr: Array):
	if arr.is_empty():
		return null
	return arr[_rng.randi_range(0, arr.size() - 1)]
