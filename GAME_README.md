# Echo Vaults — Playable Build (Fas 1: Vertical Slice)

A runnable **Godot 4.x** project implementing the **Fas 1 vertical slice** from
[`docs/echo_vaults_architecture.md`](docs/echo_vaults_architecture.md): the full
core loop **Enter → loot → shoot → extract (or die)**, built on the data-driven,
event-bus architecture so later phases bolt straight on.

## Run it

1. Open the project folder in **Godot 4.3** (or any 4.x — adjust `config/features`
   in `project.godot` if your editor warns about the version).
2. Press **F5** (Play). The main scene boots straight into a raid.

## Controls

| Action | Input |
|---|---|
| Move | `W` `A` `S` `D` |
| Sprint (loud!) | `Shift` |
| Dodge | `Space` |
| Aim | Mouse |
| Fire | Left Mouse Button |
| Reload | `R` |
| Return to hub (on result screen) | `Enter` |

## The loop

- Sneak/shoot through a static **Industrial Vault**. Guards **patrol**, **investigate**
  noise/last-known-position, and **chase + shoot** on sight (line-of-sight is blocked
  by walls — use cover).
- Grab green **loot** (and drops from kills).
- When the **timer** hits zero the **ALARM** fires and every guard starts hunting you —
  staying longer is riskier (risk/reward groundwork).
- Reach the **green extraction pad** and stand on it until the ring fills to **extract**
  and bank your loot. Die first and you lose it all.

## How this maps to the architecture

| Arch deliverable | Where |
|---|---|
| B. Autoloads | `autoloads/event_bus.gd`, `game_manager.gd`, `run_manager.gd`, `scripts/core/rng.gd` |
| C. Data-driven Resources | `resources/**` (schemas) + `data/**/*.tres` (content) |
| D. State machines | `scripts/core/state_machine/` (generic) + `scripts/enemies/states/` (Patrol/Chase/Search); Player uses an enum FSM |
| F. EventBus | `autoloads/event_bus.gd` — combat/alarm/loot/extraction stay decoupled |
| G. Persistence split | run-only state lives in `RunManager` and is never saved (SaveManager + hub land in Fas 2) |

## Notable implementation choices

- **Built in code, not the editor.** Player, enemies, walls, loot, projectiles and HUD
  construct their own collision shapes and placeholder visuals (`_draw`) at runtime, so
  the repo carries only two trivial `.tscn` files (`main`, `raid`) and stays diff-friendly.
- **Placeholder art**: circles/rectangles. Swap in sprites later without touching logic.
- Collision layers: `1` world · `2` player · `4` enemy · `32` pickups.

## Next phases (per the architecture milestone plan)

- **Fas 2** — Hub + persistence (StashManager, SaveManager), loadout UI, procedural
  vault generation.
- **Fas 3** — Full AlarmManager 0–3 Tension Loop, Scout/Heavy, waves, loot scaling.
- **Fas 4** — Boss phases + arena lock/unlock. **Fas 5** — Crafting/modding + Echo effects.
  **Fas 6** — Meta-progression, Echo Lab, run modifiers.

Tell me to continue and I'll build the next phase.
