extends Node
## Global signal hub (deliverable F). Holds ONLY signal declarations — no logic.
## Producers call EventBus.<signal>.emit(...); consumers connect in _ready().
## This is what keeps combat / alarm / loot / extraction decoupled.

# --- Combat ---
signal enemy_died(enemy_data, position)
signal player_damaged(amount, source)
signal player_died()

# --- Perception / Tension Loop ---
signal noise_emitted(position, radius, source)
signal alarm_triggered()          ## Fas 1 stand-in for the full 0–3 AlarmManager (Fas 3)

# --- Loot ---
signal item_picked_up(item_data)

# --- Run / Extraction ---
signal run_started(vault_data)
signal timer_tick(remaining)
signal timer_expired()
signal extraction_started(point)
signal extraction_completed(loot)
signal run_ended(result)

# --- Meta / UI ---
signal game_state_changed(old_state, new_state)
