# Echo Vaults — Godot Systemarkitektur

> Arkitekturförslag för en top-down extraction roguelite-shooter i **Godot 4.x (GDScript)**.
> Detta dokument svarar på leverablerna **A–I** i designpromptens kapitel 3.
> Fokus: modulär, datadriven, solo-dev-vänlig arkitektur med en spelbar vertical slice först.

**Innehåll**

- [A. Projektstruktur](#a-projektstruktur)
- [B. Autoload-singletons](#b-autoload-singletons)
- [C. Core Resource-klasser](#c-core-resource-klasser)
- [D. State machines](#d-state-machines)
- [E. Proceduralgenerering](#e-proceduralgenerering)
- [F. Event/signal-arkitektur](#f-eventsignal-arkitektur)
- [G. Save/Persistence-system](#g-savepersistence-system)
- [H. Milestone-plan](#h-milestone-plan)
- [I. Öppna frågor](#i-öppna-frågor)

> **Språkval (GDScript vs C#):** Bygg allt i **GDScript**. Med pooling och fysik-undantag (se E/F) håller GDScript 4.x lätt hundratals samtidiga fiender/projektiler i en top-down 2D-titel. Enda system jag flaggar som *möjlig* C#-kandidat är tung procedurell generering om vault-storleken växer mycket (tusentals rum) — men det är inte aktuellt för en vertical slice. Rekommendation: **inget C# nu**, omvärdera först om profilern visar ett konkret problem.

---

## A. Projektstruktur

```
res://
├── project.godot
├── autoloads/                      # Singletons (registreras i Project Settings → Autoload)
│   ├── game_manager.gd             # GameManager
│   ├── run_manager.gd              # RunManager
│   ├── alarm_manager.gd            # AlarmManager (Tension Loop)
│   ├── loot_manager.gd             # LootManager
│   ├── stash_manager.gd            # StashManager (permanent ekonomi/lager)
│   ├── economy_manager.gd          # EconomyManager (currency, priser, sälj/nedbrytning)
│   ├── save_manager.gd             # SaveManager
│   └── event_bus.gd                # EventBus (global signal-hub)
│
├── data/                           # ALLT spelinnehåll som .tres (datadrivet)
│   ├── weapons/                    # WeaponData (*.tres)
│   ├── mods/                       # ModData / EchoAttachmentData
│   ├── armor/                      # ArmorData
│   ├── consumables/                # ConsumableData
│   ├── enemies/                    # EnemyData
│   ├── bosses/                     # BossData
│   ├── vaults/                     # VaultData (vault-typer + genereringsparametrar)
│   ├── run_modifiers/              # RunModifierData
│   ├── echo_abilities/             # EchoAbilityData
│   ├── loot_tables/                # LootTableData
│   └── recipes/                    # CraftingRecipeData
│
├── resources/                      # Resource-KLASSER (class_name def, ingen instansdata)
│   ├── items/
│   │   ├── item_data.gd            # ItemData (basklass för alla items)
│   │   ├── weapon_data.gd
│   │   ├── mod_data.gd
│   │   ├── armor_data.gd
│   │   └── consumable_data.gd
│   ├── entities/
│   │   ├── enemy_data.gd
│   │   └── boss_data.gd
│   ├── world/
│   │   ├── vault_data.gd
│   │   ├── room_template_data.gd
│   │   └── loot_table_data.gd
│   ├── progression/
│   │   ├── echo_ability_data.gd
│   │   ├── meta_upgrade_data.gd
│   │   └── run_modifier_data.gd
│   └── crafting/
│       └── crafting_recipe_data.gd
│
├── scenes/
│   ├── boot/
│   │   └── main.tscn               # Entry point — laddar hub eller fortsätter save
│   ├── hub/                        # Out-of-Raid
│   │   ├── hub.tscn
│   │   ├── stash_ui.tscn
│   │   ├── loadout_ui.tscn
│   │   ├── crafting_station.tscn
│   │   ├── modding_station.tscn
│   │   ├── echo_lab.tscn
│   │   ├── meta_progression_ui.tscn
│   │   └── map_terminal.tscn
│   ├── raid/                       # In-Raid
│   │   ├── raid.tscn               # Rotscen för en raid (laddar genererad vault)
│   │   ├── vault_root.tscn         # Container för genererad nivå
│   │   └── extraction_point.tscn
│   ├── actors/
│   │   ├── player/
│   │   │   ├── player.tscn
│   │   │   └── player.gd
│   │   ├── enemies/
│   │   │   ├── enemy_base.tscn     # Datadriven: tar EnemyData
│   │   │   └── boss_base.tscn
│   │   └── projectiles/
│   │       └── projectile.tscn     # Poolad
│   ├── world/
│   │   ├── room.tscn
│   │   ├── corridor.tscn
│   │   ├── door.tscn               # sparkas/hackas/låses
│   │   ├── breakable_wall.tscn
│   │   └── loot_container.tscn
│   └── ui/
│       ├── hud.tscn
│       ├── inventory_grid.tscn
│       └── tension_meter.tscn
│
├── scripts/
│   ├── core/
│   │   ├── state_machine/
│   │   │   ├── state_machine.gd    # Generisk FSM
│   │   │   └── state.gd            # Bas-state
│   │   ├── object_pool.gd          # Pooling (projektiler, fiender)
│   │   └── rng.gd                  # Seedbar RNG-wrapper
│   ├── player/
│   │   ├── states/                 # idle/move/sprint/dodge/combat/dead
│   │   ├── player_inventory.gd
│   │   └── noise_emitter.gd
│   ├── enemies/
│   │   ├── states/                 # patrol/investigate/alert/combat/search
│   │   ├── enemy_controller.gd
│   │   ├── perception.gd           # hörsel + syn
│   │   └── reinforcement.gd
│   ├── boss/
│   │   ├── states/                 # phase1/phase2/phase3 + arena_lock
│   │   └── boss_controller.gd
│   ├── combat/
│   │   ├── weapon.gd               # runtime-vapen byggt från WeaponData + mods
│   │   ├── damage.gd               # DamagePacket-struct
│   │   ├── hitbox.gd / hurtbox.gd
│   │   └── echo_effects/           # chain_lightning.gd, pierce.gd, warp.gd, stun.gd
│   ├── world/
│   │   ├── generation/
│   │   │   ├── vault_generator.gd  # room-graph + corridor connector
│   │   │   ├── room_graph.gd
│   │   │   └── room_placer.gd
│   │   └── loot/
│   │       └── loot_spawner.gd
│   └── ui/
│
├── tests/                          # GUT eller enkla testscener
│   └── ...
└── assets/                         # art, ljud, fonts, shaders
    ├── sprites/
    ├── audio/
    └── shaders/
```

**Princip:** `resources/*.gd` definierar `class_name` (schemat). `data/*.tres` är instanserna (innehållet). Designern lägger till nytt innehåll genom att skapa nya `.tres` — aldrig genom att röra kod.

---

## B. Autoload-singletons

Registreras i Project Settings → Autoload, i denna ordning (beroenden uppifrån och ner). **EventBus laddas först** så alla andra kan koppla signaler i `_ready()`.

| Singleton | Ansvar | Sänder | Lyssnar på |
|---|---|---|---|
| **EventBus** | Global signal-hub. Innehåller endast signaldeklarationer, ingen logik. Bryter all tight coupling. | (vidarebefordrar inte — andra emit:ar på den) | — |
| **GameManager** | Övergripande spelläge (`BOOT → HUB → LOADING_RAID → IN_RAID → RAID_RESULT → HUB`). Scenbyten. Pausning. | `game_state_changed` | `EventBus.player_died`, `EventBus.extraction_completed` |
| **RunManager** | Allt run-only state: aktuell loadout, aktiva `RunModifierData`, vald `VaultData`, raid-timer, run-seed, vad spelaren plockat upp under raiden. Nollställs vid raid-slut. | `run_started`, `run_ended(result)`, `timer_expired` | `EventBus.extraction_completed`, `EventBus.player_died` |
| **AlarmManager** | Tension Loop. Äger alarm-state (0–3) via en FSM. Eskalerar på buller/timer/kamera. Styr wave-spawns och boss-wing-unlock. | `alarm_state_changed(old,new)`, `wave_requested(intensity)`, `boss_wing_unlocked` | `EventBus.noise_emitted`, `EventBus.enemy_died`, `EventBus.player_spotted`, `RunManager.timer_expired` |
| **LootManager** | Rullar loot från `LootTableData` med scaling (timer, alarm, elite/boss-kills, zon-risk). Avgör drop-kvalitet. | `loot_rolled(items, position)` | `EventBus.enemy_died`, `EventBus.container_opened`, `EventBus.boss_defeated` |
| **StashManager** | Permanent lager. Add/remove items, stash-storlek (påverkas av meta-upgrades). Tar emot extraherad loot. | `stash_changed` | `EventBus.extraction_completed` (commit av run-loot), meta-upgrades |
| **EconomyManager** | Currency (Echo Fragments), köp/sälj, nedbrytning till material, priser. | `currency_changed(amount)` | `EventBus.item_sold`, `EventBus.item_dismantled` |
| **SaveManager** | Serialiserar/deserialiserar permanent data (stash, meta, Echo Lab, ekonomi, settings). Skriver **endast** vid hub-return/explicit save — aldrig under raid. | `save_completed`, `load_completed` | `GameManager.game_state_changed` (→ HUB triggar save) |

> **MetaProgressionManager**: kan vara egen autoload eller en modul som ägs av `StashManager`/`GameManager`. För solo-dev-enkelhet börjar den som en del av `GameManager` och bryts ut om den växer.

**Koppling i praktiken:** Systemen pratar nästan aldrig direkt. T.ex. när en fiende dör emit:ar fienden `EventBus.enemy_died(enemy_data, position)`. `LootManager`, `AlarmManager` och en eventuell quest-modul lyssnar oberoende. Ingen av dem känner till varandra.

---

## C. Core Resource-klasser

Alla ärver `Resource` och har `class_name`. Fält listas (typer angivna) — ej full implementation.

### `ItemData` (basklass, `resources/items/item_data.gd`)
```gdscript
class_name ItemData extends Resource
@export var id: StringName            # unik nyckel, används i save/loot-tables
@export var display_name: String
@export_multiline var description: String
@export var icon: Texture2D
@export var rarity: Rarity             # enum: COMMON, UNCOMMON, RARE, EPIC, LEGENDARY, ECHO
@export var base_value: int            # för sälj/ekonomi
@export var weight: float              # mot carry capacity
@export var stack_size: int = 1
@export var grid_size: Vector2i = Vector2i.ONE   # Tarkov-style inventory footprint
@export var dismantle_yield: Array[ItemStack]    # material vid nedbrytning
```

### `WeaponData` (`weapon_data.gd extends ItemData`)
```gdscript
@export var weapon_class: WeaponClass  # PISTOL, SMG, RIFLE, SHOTGUN, MELEE...
@export var damage: float
@export var fire_rate: float           # skott/sek
@export var projectile_scene: PackedScene
@export var projectile_speed: float
@export var pellet_count: int = 1      # shotgun
@export var spread_degrees: float
@export var recoil: float
@export var mag_size: int
@export var reload_time: float
@export var ammo_type: StringName      # matchar ConsumableData/ammo-id
@export var headshot_multiplier: float = 2.5
@export var noise_radius: float        # → Tension Loop
@export var mod_slots: Array[ModSlotType]   # BARREL, MAGAZINE, STOCK, SIGHT, ECHO
@export var loot_tier: int             # för loot-scaling/gating
```

### `ModData` / `EchoAttachmentData` (`mod_data.gd extends ItemData`)
```gdscript
@export var slot_type: ModSlotType
@export var is_echo: bool = false      # magisk/scifi vs vanlig
@export var is_legendary: bool = false # endast boss-loot
@export var stat_modifiers: Array[StatModifier]   # additiva/multiplikativa deltas
@export var echo_effect: EchoEffectType            # CHAIN_LIGHTNING, PIERCE, WARP, KINETIC_STUN, NONE
@export var echo_effect_params: Dictionary         # t.ex. {"bounces":3,"radius":120}
@export var required_weapon_classes: Array[WeaponClass]  # tom = alla
```

### `ArmorData` (`armor_data.gd extends ItemData`)
```gdscript
@export var armor_value: float
@export var damage_resistance: float   # 0..1
@export var durability: int
@export var move_speed_penalty: float
@export var noise_modifier: float
@export var slots: Array[ModSlotType]  # vissa armar kan ha echo-slots
```

### `ConsumableData` (`consumable_data.gd extends ItemData`)
```gdscript
@export var consumable_type: ConsumableType  # MEDKIT, STIM, GRENADE, BUFF, AMMO, TOOL
@export var use_time: float
@export var effect: EchoAbilityData          # återanvänder effekt-systemet, eller egen StatusEffect
@export var heal_amount: float
@export var ammo_amount: int                 # om ammo
@export var ammo_type: StringName
```

### `EnemyData` (`enemy_data.gd extends Resource`)
```gdscript
@export var id: StringName
@export var display_name: String
@export var archetype: EnemyArchetype  # SCOUT, GUARD, HEAVY, ARCANE_MUTANT, ELITE
@export var scene: PackedScene         # enemy_base.tscn variant
@export var max_hp: float
@export var move_speed: float
@export var damage: float
@export var weapon: WeaponData         # null = melee/special
@export var hearing_radius: float
@export var sight_range: float
@export var sight_angle: float
@export var calls_reinforcements: bool # Scout = true
@export var xp_value: int
@export var loot_table: LootTableData
@export var echo_abilities: Array[EchoAbilityData]   # Elite
@export var random_modifier_pool: Array[StatModifier] # Arcane Mutant
@export var alarm_aggression_curve: Curve            # beteende vs alarm-state
```

### `VaultData` (`vault_data.gd extends Resource`)
```gdscript
@export var id: StringName
@export var display_name: String
@export var theme: VaultTheme          # INDUSTRIAL, ARCANE, OVERGROWN, MILITARY_EXP
@export var difficulty: int
@export var min_rooms: int
@export var max_rooms: int
@export var room_templates: Array[RoomTemplateData]
@export var enemy_pool: Array[EnemyData]
@export var boss: BossData
@export var base_loot_table: LootTableData
@export var raid_time_seconds: float   # global timer innan larm
@export var loot_rating: int
@export var allowed_modifiers: Array[RunModifierData]
@export var environmental_hazards: Array[PackedScene]
```

### `RunModifierData` (`run_modifier_data.gd extends Resource`)
```gdscript
@export var id: StringName
@export var display_name: String
@export var description: String
@export var is_temporary: bool = true  # förloras vid extract/död
@export var cost: int                  # köps i hub
@export var stat_modifiers: Array[StatModifier]      # t.ex. +10% reload
@export var risk_factor: float         # >1 = svårare (t.ex. boss +15% men bättre loot)
@export var loot_multiplier: float
@export var difficulty_multiplier: float
@export var grants_extra_slot: bool    # +1 temporär echo-slot
```

### `EchoAbilityData` (`echo_ability_data.gd extends Resource`)
```gdscript
@export var id: StringName
@export var display_name: String
@export var description: String
@export var ability_type: EchoAbilityType  # CHAIN_LIGHTNING, REALITY_FRACTURE, VOID_DASH, ECHO_SHIELD, LOOT_PHASING, FATE_REROLL
@export var cooldown: float
@export var duration: float
@export var params: Dictionary
@export var unlock_cost: Dictionary    # {echo_fragments:int, boss_material:StringName...}
@export var prerequisites: Array[StringName]  # echo-träd-beroenden
@export var ability_script: GDScript   # körbar logik (Strategy-pattern)
```

### `BossData` (`boss_data.gd extends EnemyData`)
```gdscript
@export var phases: Array[BossPhaseData]   # Phase1/2/3 mönster
@export var arena_scene: PackedScene
@export var unlock_condition: BossUnlockType  # TIMER, HACK_TERMINALS, ENEMY_COUNT
@export var unlock_threshold: int             # antal terminals / enemy count
@export var can_chase: bool = true            # lämnar zon vid Overrun
@export var enrage_hp_threshold: float = 0.5  # dörr öppnas igen vid 50%
@export var legendary_loot_table: LootTableData
@export var alarm_buff_loot_table: LootTableData  # buffad loot om dödad i state 3
```

### Stödklasser
```gdscript
class_name StatModifier extends Resource     # {stat:StringName, op:Op(ADD/MUL), value:float}
class_name ItemStack extends Resource        # {item:ItemData, count:int}
class_name LootTableData extends Resource     # viktade entries + quality-scaling-kurvor
class_name RoomTemplateData extends Resource  # se sektion E
class_name MetaUpgradeData extends Resource   # permanent upgrade (HP+, stash+, modslot+...)
class_name CraftingRecipeData extends Resource # inputs:Array[ItemStack], output:ItemStack, craft_time, required_station
class_name BossPhaseData extends Resource     # hp_threshold, attack_patterns, spawns
```

**Loot-scaling, crafting & modding täcks av:** `loot_tier`/`rarity`/`base_value` (scaling & ekonomi), `dismantle_yield` + `CraftingRecipeData` (crafting/nedbrytning), `mod_slots`/`slot_type`/`stat_modifiers`/`echo_effect` (modding). Allt drivs av `.tres` → ny balans/innehåll utan kod.

---

## D. State machines

Generisk, återanvändbar FSM (`scripts/core/state_machine/`):

```gdscript
# state.gd
class_name State extends Node
func enter(_msg := {}) -> void: pass
func exit() -> void: pass
func update(_delta: float) -> void: pass
func physics_update(_delta: float) -> void: pass
signal transition(to_state: StringName, msg: Dictionary)

# state_machine.gd
class_name StateMachine extends Node
@export var initial_state: State
var current: State
func change_state(name: StringName, msg := {}) -> void: ...
```
States är barn-noder; FSM:n vidarebefordrar `_process`/`_physics_process`. Detta gör att Player, Enemy, Boss och Alarm alla delar samma maskineri men har egna state-script.

### 1. Player FSM (`scripts/player/states/`)
`Idle → Move → Sprint → Dodge → Combat → Dead`
- **Idle/Move/Sprint:** rörelse + `NoiseEmitter` skalar buller (Sprint = hög, → `EventBus.noise_emitted`).
- **Dodge/Slide:** i-frames, gated av `EchoAbilityData` (t.ex. Void Dash).
- **Combat:** skjuter/laddar om; kan överlappa rörelse (combat är egentligen ett *substate*/flagga snarare än exklusivt — se öppen fråga I).
- **Dead:** triggar `EventBus.player_died` → RunManager (run-loot förloras).

### 2. Enemy AI FSM (`scripts/enemies/states/`)
`Patrol → Investigate → Alert → Combat → Search`
Driven av `Perception` (hörsel via `EventBus.noise_emitted` + syn via raycast/vision-cone):
- **Patrol:** waypoints/idle.
- **Investigate:** hörde ljud → går mot senast kända position.
- **Alert:** såg spelaren → `EventBus.player_spotted` (matar AlarmManager), Scout ropar förstärkning.
- **Combat:** skjuter, tar cover.
- **Search:** tappade spelaren → söker runt sista position, faller tillbaka till Patrol efter timeout.
- Alla tröskelvärden skalas av AlarmManagerns state (mer aggressiv vid högre tension).

### 3. Tension / Alarm FSM (`autoloads/alarm_manager.gd`)
`State 0 Calm → State 1 Investigate → State 2 Alarm → State 3 Overrun`
- Eskaleras av: ackumulerat buller, sedd-av-kamera, fiende-radiosignal vid död, **timer-utgång** (hoppar minst till Alarm).
- **State 2:** börjar `wave_requested`-spawns.
- **State 3:** waves intensifieras, boss kan lämna zon, extraction blir farlig, loot +20–40%.
- De-eskalering möjlig (state 1→0) om spelaren bryter sikt/ljud länge nog; state 2+ är i regel enkelriktat under en raid (öppen fråga I).
- Emit:ar `alarm_state_changed` → HUD tension-meter, LootManager (scaling), boss-unlock.

### 4. Boss Phase FSM (`scripts/boss/states/`)
`ArenaLock → Phase1 → Phase2 → Phase3 → (Chase) → Defeated`
- **ArenaLock:** dörr stängs vid entry.
- **Phase-transitioner** drivs av `BossPhaseData.hp_threshold`.
- Vid **50% HP** (`enrage_hp_threshold`): dörr öppnas, `can_chase` aktiveras → boss kan jaga ut i kartan och `wave_requested` via AlarmManager.
- **Phase3:** teleport/summon/mutated (endgame).
- **Defeated:** `EventBus.boss_defeated` → LootManager väljer legendary vs alarm-buffad tabell beroende på alarm-state.

---

## E. Proceduralgenerering

**Plats:** `scripts/world/generation/`. Körs i `RunManager` när en raid startar, med **seedbar RNG** (`scripts/core/rng.gd`) så att en run kan reproduceras/debuggas.

**Algoritm — room-graph + corridor connector (rekommenderad för solo-dev):**
1. **Välj rumsbudget** från `VaultData.min_rooms..max_rooms`.
2. **Bygg rumsgraf** (`room_graph.gd`): börja med ett `ENTRANCE`-rum, väx en graf genom att lägga till noder med rumstyper (`LOOT`, `COMBAT_ARENA`, `STORAGE`, `OFFICE`, `LABORATORY`, `HAZARD`) enligt viktade regler. Garantera exakt **1 boss-wing-nod** som markeras `locked`.
3. **Placera rum** (`room_placer.gd`): instansiera `RoomTemplateData.scene` per nod på ett rutnät, undvik överlapp (enkel bin-packing/grid). Varje template har definierade **dörr-/connector-portar**.
4. **Koppla korridorer** (`corridor_connector`): koppla grannar i grafen via `corridor.tscn`; lägg ev. extra loop-kanter för icke-linjär layout.
5. **Boss wing-lås:** boss-wing-dörren förblir låst tills `AlarmManager.boss_wing_unlocked` (timer/terminals/enemy-count enligt `BossData.unlock_condition`).
6. **Befolka:** `loot_spawner.gd` placerar `loot_container.tscn` i loot-rum; enemy-spawners placerar fiender från `VaultData.enemy_pool`; extraction-punkter (1 statisk + 1–3 random).

**`RoomTemplateData`** (datadrivet rum):
```gdscript
class_name RoomTemplateData extends Resource
@export var scene: PackedScene
@export var room_type: RoomType
@export var size: Vector2i
@export var connector_ports: Array[Vector2i]   # dörrpositioner
@export var loot_spawn_points: int
@export var enemy_spawn_points: int
@export var weight: float                       # sannolikhet i grafen
@export var allowed_themes: Array[VaultTheme]
```

> **Strategi:** handgjorda rum-templates kopplade procedurellt ger bäst combat-feel för en Hotline Miami-titel (rena, läsbara arenor) med minst risk jämfört med ren tile-by-tile-generering. Börja med ~6–10 templates per tema.

---

## F. Event/signal-arkitektur

**`EventBus` (autoload)** — enda källan till globala signaler. Inga referenser mellan system; producenter emit:ar, konsumenter `connect`:ar i `_ready()`.

```gdscript
# autoloads/event_bus.gd
extends Node

# --- Combat ---
signal damage_dealt(target, packet)            # packet: Damage
signal enemy_died(enemy_data: EnemyData, position: Vector2)
signal boss_phase_changed(phase: int)
signal boss_defeated(boss_data: BossData, position: Vector2, alarm_state: int)
signal player_damaged(amount: float, source)
signal player_died()

# --- Perception / Alarm (Tension Loop) ---
signal noise_emitted(position: Vector2, radius: float, source)
signal player_spotted(by, position: Vector2)
signal camera_triggered(position: Vector2)
signal alarm_state_changed(old_state: int, new_state: int)
signal wave_requested(intensity: int)
signal boss_wing_unlocked()

# --- Loot / Economy ---
signal loot_rolled(items: Array, position: Vector2)
signal item_picked_up(stack)
signal container_opened(container)
signal item_sold(stack); signal item_dismantled(stack)
signal currency_changed(amount: int)

# --- Run / Extraction ---
signal run_started(vault_data: VaultData)
signal timer_tick(remaining: float)
signal timer_expired()
signal extraction_started(point)
signal extraction_completed(extracted_loot: Array)
signal run_ended(result: int)                  # EXTRACTED / DIED / ABORTED

# --- Meta / UI ---
signal game_state_changed(old_state: int, new_state: int)
signal stash_changed()
signal save_completed(); signal load_completed()
```

**Exempelflöde (utan tight coupling):**
`Enemy` dör → `EventBus.enemy_died.emit(data, pos)`
→ `LootManager` rullar loot (`loot_rolled`) → `LootSpawner` instansierar pickup
→ `AlarmManager` ökar tension om fienden hann skicka radiosignal
→ HUD uppdaterar kill-count.
Ingen av dessa känner till de andra.

**Riktlinje:** Använd EventBus för *cross-system, broadcast*-händelser. Lokala, 1-till-1-relationer (t.ex. en vapen-nod → dess ägar-player) använder **direkta signaler/referenser** — inte EventBus — för att undvika att globala bussen blir en soptunna.

---

## G. Save/Persistence-system

**Grundregel:** Skriv till disk **endast vid hub-return / explicit save** — *aldrig* mitt under en raid. Run-state lever bara i minnet (`RunManager`) och kastas vid extract/död.

**Separata datablock (separata filer för robusthet):**

| Block | Persistens | Lagras i | Skrivs när |
|---|---|---|---|
| **Stash** | Permanent | `user://save/stash.tres` (eller JSON) | Hub-return efter lyckad extract |
| **Meta-progression** | Permanent | `user://save/meta.tres` | När en meta-upgrade köps (hub) |
| **Echo Lab-progression** | Permanent | `user://save/echo_lab.tres` | När en Echo Ability låses upp (hub) |
| **Ekonomi** (Echo Fragments) | Permanent | del av `meta.tres` | Hub-transaktioner |
| **Aktuell loadout** | Permanent (val) | `user://save/loadout.tres` | När loadout bekräftas i hub |
| **Temporary run modifiers** | **Run-only** | endast `RunManager` (minne) | **sparas aldrig** |
| **Aktuell raid-state** | **Run-only** | endast `RunManager` (minne) | **sparas aldrig** |
| Settings | Permanent | `user://settings.cfg` | Vid ändring |

**Modell:**
```gdscript
# Permanent profil (serialiseras av SaveManager)
class_name PlayerProfile extends Resource
@export var stash: Array[ItemStack]
@export var stash_capacity: int
@export var currency: int
@export var meta_upgrades: Array[StringName]      # köpta MetaUpgradeData.id
@export var unlocked_echo_abilities: Array[StringName]
@export var unlocked_vaults: Array[StringName]
@export var saved_loadout: LoadoutData

# Run-only (lever i RunManager, sparas ALDRIG)
class_name RunState extends RefCounted
var seed: int
var vault: VaultData
var loadout: LoadoutData               # KOPIA av items som tagits in (riskerade)
var active_modifiers: Array[RunModifierData]
var collected_loot: Array[ItemStack]   # plockat under raiden
var elapsed_time: float
var alarm_state: int
var elite_kills: int
var boss_defeated: bool
```

**Extraction-commit (kärnan i gear-loss):**
- **Extract lyckas:** `RunManager.run_state.collected_loot` + överlevande `loadout`-items → `StashManager.add()` → `SaveManager.save()`.
- **Spelaren dör:** `collected_loot` **och** `loadout`-items kastas (riskerade items förloras). Meta/Echo Lab orörd. `SaveManager.save()` (för att persistera ev. XP/meta som tjänats utanför stash).

**Format:** Börja med Godots `ResourceSaver`/`load` på `PlayerProfile` (snabbt, typat). Byt till JSON + versionsfält först om modd-stöd/migrering blir aktuellt. Inkludera ett `save_version: int` från dag 1 för migrering. Atomär skrivning (skriv till temp-fil, `rename`) för att undvika korrupta saves.

---

## H. Milestone-plan

Varje fas är **spelbar** och bygger på den förra. Bygg ej fas N+1 förrän N är stabil.

### Fas 1 — Vertical Slice (kärnloopen, spelbar)
*Mål: Enter → loot → skjut → extract, end-to-end.*
- Generisk FSM, Player FSM (idle/move/sprint/combat/dead), 360° rörelse + en hitscan/projektil-vapen.
- **En** `VaultData`, statisk eller minimalt genererad layout (3–5 rum), **en** fiendetyp (Guard) med enkel patrol→combat-AI.
- Grund-loot: en pickup, plockas upp, **en statisk extraction** → "raid complete".
- Autoloads: `GameManager`, `RunManager`, `EventBus` (minimum).
- `WeaponData`, `EnemyData`, `ItemData`, `VaultData` som `.tres`.
- *Ingen* hub än — starta raid direkt från `main.tscn`.

### Fas 2 — Hub-loop & persistens
- `hub.tscn`, `StashManager`, `SaveManager`, `EconomyManager`, `LoadoutData`.
- Gear-loss-logik: extract → loot till stash & spara; död → förlust.
- `loadout_ui` + `stash_ui`. Hub ⇄ Raid scenflöde via GameManager.
- Procedurell vault-generering (room-graph + corridors), `RoomTemplateData`.

### Fas 3 — Tension Loop & fiende-bredd
- `AlarmManager` med full 0–3 FSM, `Perception` (hörsel/syn), `NoiseEmitter`.
- Wave-spawning, reinforcement (Scout), kameror.
- Fler fiendetyper (Scout, Heavy), HUD tension-meter, raid-timer.
- Loot-scaling i `LootManager` (timer/alarm).

### Fas 4 — Boss-system
- `BossData`, Boss Phase FSM (Phase 1–3), arena lock/unlock, chase-logik.
- Unlock-villkor (timer/terminals/enemy-count), legendary loot + alarm-buffad loot.
- Multipla + random extraction points med inspelningstid/minivåg.

### Fas 5 — Crafting, Modding & Echo Attachments
- `crafting_station`, `modding_station`, `CraftingRecipeData`, nedbrytning.
- `ModData`/`EchoAttachmentData`, mod-slots på vapen, drag-and-drop modding-UI.
- Echo-effekter i strid (chain lightning, pierce, warp, stun) via `echo_effects/`.
- Arcane Mutant + Elite-fiender.

### Fas 6 — Meta-progression, Echo Lab & variation
- `MetaUpgradeData`-träd, permanenta upgrades (HP, stash, modslots…).
- `EchoAbilityData` + Echo Lab progressionsträd, ability-slots.
- `RunModifierData` + `map_terminal` (vault-val, svårighet, environmental modifiers).
- Fler vault-teman, balanspass, endless/story-hooks.

> **Solo-dev-not:** Object pooling (projektiler/fiender) och en seedbar RNG bör in redan i Fas 1/3 eftersom de är jobbiga att retrofitta. Allt annat är additivt tack vare den datadrivna + EventBus-arkitekturen.

---

## I. Öppna frågor

Antaganden jag gjort, samt beslut speldesignern bör ta:

1. **Inventory-modell:** Tarkov-style grid (`grid_size`) eller enklare slot-/viktbaserat? Jag antog grid + vikt — det påverkar UI-komplexitet rejält. *Rekommendation för solo-dev: börja slot+vikt, grid senare.*
2. **Modslots:** Exakt antal slots per vapenklass och vilka slot-typer per vapen? (`mod_slots` är öppen array nu.)
3. **Echo-ability-slots:** Hur många samtidigt aktiva abilities? Är de always-on (passiva) eller aktiva med cooldown? Blandat?
4. **Combat som state:** Är "Combat" ett exklusivt player-state eller en flagga ovanpå rörelse (man skjuter medan man rör sig)? Jag lutar åt **flagga/substate** för Hotline Miami-feel.
5. **Alarm de-eskalering:** Kan tension sjunka tillbaka (state 2→1) eller är det enkelriktat efter att larmet gått? Jag antog: 0↔1 reversibelt, 2+ enkelriktat per raid.
6. **Raid-timer-semantik:** Är timern tid *tills larm* eller *hård deadline för extraction*? Designdok antyder "tiden tar slut → larm". Jag antog timer = trigger för minst State 2, inte hård raid-slut.
7. **Vault-storlek:** Konkret `min_rooms/max_rooms` per tema? (Påverkar generering + prestanda.)
8. **XP/progression-formel:** Exakt XP-kurva och vad XP låser upp vs. vad Echo Fragments köper. Två valutor (XP + Fragments) eller en?
9. **Loot-scaling-formel:** Exakt hur timer/alarm/elite/boss/zon-risk kombineras till slutlig drop-kvalitet (additivt vs multiplikativt). Behövs konkreta tal för balansering.
10. **Permadeath-omfattning:** Förloras *all* inburen gear vid död (full Tarkov) eller finns insurance/secure-container? Påverkar svårighetskurva och nybörjarvänlighet.
11. **Death utanför extraction:** Behåller spelaren meta-XP/fragments tjänade under en run om hen dör, eller endast det som är committat? Jag antog meta tjänas direkt men loot riskeras.
12. **Co-op/multiplayer:** Antar **single-player only**. Om multiplayer någonsin är aktuellt påverkar det save-/EventBus-arkitekturen kraftigt och bör flaggas nu.

---

*Nästa steg: bekräfta de öppna frågorna (särskilt 1, 4, 6, 10) innan Fas 1-implementation, eftersom de påverkar grundläggande klasser (inventory, player FSM, RunManager, save-modell).*
