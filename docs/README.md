# Below the Hollow — Build Notes (Vertical Slice v0.1)

Psychological horror roguelike, Godot 4.3+, PS2-era low-poly with readable
lighting. Built from the Developer Bible V3.

## How to run

1. Install **Godot 4.3 or newer** (standard build, no C#): https://godotengine.org/download
2. Open Godot → **Import** → select `BelowTheHollow/project.godot` → **Edit**.
3. Press **F5** (Run Project). `scenes/core/Main.tscn` boots the game.

> The editor Input Map tab will look empty — actions are registered at
> runtime by `SettingsManager` (see the note in `project.godot`). This is
> intentional: it is version-proof and enables in-game key rebinding.

## Architecture (code-first)

Only **one** scene file exists (`scenes/core/Main.tscn`). Every other node
tree — UI screens, the player, enemies, whole procedural stages — is built in
GDScript. This removes all scene-reference/UID fragility and keeps every
integration point visible in code.

### Autoload order (project.godot)
| Autoload | File | Role |
|---|---|---|
| EventBus | scripts/core/EventBus.gd | global signal hub (all cross-system signals) |
| Database | scripts/data/Database.gd | ALL tunable data: classes, stats formulas, stages, enemies, upgrades, 120 items |
| AudioManager | scripts/audio/AudioManager.gd | buses + synthesized placeholder SFX |
| SettingsManager | scripts/core/SettingsManager.gd | settings.cfg, input map, video/audio apply |
| SaveManager | scripts/core/SaveManager.gd | profile/run/statistics JSON |
| RunManager | scripts/core/RunManager.gd | seed, class, stage index, 10-upgrade cap, essence |
| GameManager | scripts/core/GameManager.gd | state machine, screen flow, stage/player lifecycle |
| DebugConsole | scripts/core/DebugConsole.gd | ` / F1 developer console |

### Gameplay flow
Title → Main Menu → Class Select → `RunManager.start_new` →
`GameManager._load_current_stage` (StageBuilder + player + SanityManager) →
exit gate → Upgrade screen (2 picks) → next stage … → Victory/Death →
profile persists, continue snapshot cleared.

## Testing checklist (current slice)

| Test | How |
|---|---|
| Menu flow | Title (any key) → New Run → pick class → Begin Descent |
| Continue disabled w/o save | Fresh install → Continue is greyed out |
| Settings persist | Change volume/brightness → Back → restart game → values kept |
| Key rebind | Settings → Controls → click a bind → press new key |
| Movement/camera | WASD + mouse; Shift sprint drains stamina; Space dodge (i-frames) |
| Lantern | Hold Q: focus cone brightens, sanity slowly recovers |
| Combat | LMB attack; hit enemies flash, damage numbers float, essence drops |
| Class differences | Archer shoots arrows; Tank slow + Guarded when still 0.75s; Swordsman perfect-dodge empowers; Bandit backstab bonus |
| Procgen | Every stage: entrance (safe), glowing role-coded props, orange exit gate |
| Enemy senses | Blind Stalker ignores you until you sprint nearby; Mimic looks like a chest until approached; Watcher freezes while watched |
| Upgrades | Exit gate → exactly 2 sequential two-card choices; 10 max per run |
| Sanity | Watch bar drain; at 70/40/10 events fire; near entrance it recovers |
| Death/Victory | `god` off, get killed → death screen with seed; `complete` x5 → victory |
| Save/continue | Mid-run: Pause → Quit to Menu → Continue resumes stage/class/upgrades |

## Debug console (` or F1)

`help` · `fps` · `startrun <class> [seed]` · `stage <n>` · `regen` ·
`complete` · `spawn <enemy> [count]` · `kill_all` · `heal` · `god` ·
`sanity <0-100>` · `upgrade` · `essence <n>` · `list enemies|classes|stages|upgrades` ·
`seed <n>` · `menu` · `quit`

Reproduce a generation bug: `startrun swordsman 12345` → identical layout
every time (all rolls derive from `RunManager.stage_rng()`).

## Slice status vs full game

DONE: menus/settings/save/continue, 4 classes + passives, stat formulas,
procgen stages (all 5 stage definitions), threat-budget enemy spawning, 11
species on the data-driven `EnemyBase` AI (state machine per bible §10),
melee/ranged combat, crits/burn/stagger, upgrades (23 in pool, 10/run),
essence, sanity drain/recovery + 3 threshold events, HUD, damage numbers,
subtitles, debug console.

NEXT (in bible build order):
1. **BossBase.gd + The Burrower** (stage 1 boss arena, 3 phases) — request: `BossBase.gd`
2. Inventory screen + item drops using the 120-item pool — request: `InventoryScreen.gd`
3. Helper NPCs (Merchant shop first) — request: `HelperBase.gd`
4. MusicDirector layered ambience/combat stems — request: `MusicDirector.gd`
5. Sanity event scheduler w/ fake-UI + hallucination actors — request: `SanityEvents.gd`
6. Species-specific enemy subclasses (Screamer cone, Bone Collector armor…)
