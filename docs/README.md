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
| Boss: Burrower | Stage 1 exit room → fight starts (boss bar appears). Dodge the lunge → scars glow → hit it during the 2.5s exposed window |
| Boss: Priest | Stage 2 (`stage 1` then walk, or `boss drowned_priest`). Phase 3: damage him during the chant to interrupt (long stagger) |
| Boss: Ancient | `stage 4` → exit room. 5 phases; at 20% two altars appear — each gives a different victory ending |
| Elite gauntlet | Stages 3/4 exit rooms spawn 4 scaled elites; gate opens when all die |
| Sealed gate | Interact with the gate before winning the fight → "sealed" + fight starts |
| Boss debug | `boss burrower` spawns any boss at the player; `boss start` triggers the stage climax; `kill_all` executes bosses too (opens the gate) |
| Items drop | Loot/secret rooms hold a rarity-colored crate; enemies drop gear ~8% (+Luck); bosses always drop non-common gear |
| Inventory | Tab opens Pack & Equipment (game pauses). Equip/Unequip/Drop; stats apply instantly; pack caps at 10 (full pack leaves crates in the world) |
| Item debug | `give random` (luck-boosted roll) or `give item_035`; equip via Tab |
| Helpers | Green/gold/blue/purple hooded figure in a side room (if the stage rolled a helper room). `E` opens their shop; Merchant sells items, Medic heals (first minor heal free), Cartographer marks the exit, Strange Child trades relics for 25 SANITY |
| Music layers | Cave drone always; dissonant tension swells as sanity drops; combat pulse when enemies chase; heavier pulse during bosses — all synthesized, no audio files |

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

DONE (boss step): `BossBase` framework (phases, HP-bar signals, shared attack
primitives: projectiles, telegraphed rings, falling rocks, hazard zones,
summons) + **The Burrower** (burrow/lunge/exposed-scars), **The Drowned
Priest** (bolts, floods, interruptible chant), **The Ancient Below** (5 phases:
heart, fake-UI lies, player echoes, collapse, choice ending → two victory
endings). Exit gates now seal until the arena boss / elite gauntlet (stages
3-4) is cleared. HUD boss bar; `boss <id>` / `boss start` debug commands.

DONE (inventory step): the 120-item pool now drops in-world (loot/secret
rooms guaranteed + seeded; enemies ~8% luck-scaled; bosses guaranteed
non-common), luck-weighted rarity rolling in `Database.roll_item_id`,
backpack (cap 10) + 5 equip slots in RunManager (persisted in the continue
snapshot), and the Tab `InventoryScreen` with equip/unequip/drop and stat
comparison. Stats from equipped gear apply instantly via StatsComponent.

DONE (helpers + music step): all four helper NPCs (`HelperBase`, one seeded
per stage in the helper room) with the `ShopScreen` — Merchant (3 stage-scaled
items), Medic (free minor heal + paid heal/sanity), Cartographer (exit
marking + discounted found item), Strange Child (relic paid in sanity +
cryptic clue). Upgrade tags wired: Merchant Credit (first item half price),
Medic Pact (heal after bosses), Cartographer Mark (exit revealed on stage
entry), No Footprints. `MusicDirector` autoload: synthesized looping
bed/tension/combat layers crossfaded by stage depth, sanity, combat and boss
state.

DONE (document-compliance step, per Appendices B/E/F/G2/J):
- **10 dedicated species scripts** (`scripts/enemies/species/`, Appendix E) on
  the shared EnemyBase: Crawler pack-aggression leaps; Blind Stalker hunts the
  LAST HEARD sound (stand still to vanish); Crystal Spider shard-spit + slowing
  webs; Mimic bites twice then flees and re-disguises; Tunnel Screamer
  interruptible scream cone (white-out + crawler summons); Bone Collector
  armor-stacks off nearby deaths, stripped by burn; Watcher statue-freeze /
  unseen rush / vanish after 3 hits; Shadow Parasite attach-drain scraped off
  by dodging, dies to burn; Hollow Monk blink + interruptible curse bolts +
  sigil summons; Faceless Echo mirrors YOUR class (color, cadence, sidesteps,
  archer echoes shoot back).
- **Active-enemy cap** (Appendix J): per-stage caps [4,5,6,8,10]; distant
  enemies sleep, nearest wake first — no runaway spawns.
- **Full ending matrix** (Appendix G2): Escape / Hollow / Mercy (aid
  Medic+Child 3x, kill no echoes) / Truth (all 5 memory relics — one hidden
  per stage) / Cycle (die on the final stage → your skeleton greets the next
  run). Ending unlocks recorded in the profile.
- **8-category sanity event library** (Appendix B): atmosphere, memory
  scenes, fake UI, false exits/loot that dissolve when approached (navigation
  + item deception), hallucination enemies (translucent, harmless, one-hit),
  audio phantoms, NPC distortion. Lantern focus blocks new events (universal
  counterplay). `sanityevent <category>` forces any of them.
- **Boss debug per Appendix F**: `boss_phase <n>`, `boss_invuln`, `boss_log`
  (attack pattern logging). Statistics now persist at run end.

NEXT (remaining polish, beyond the doc's core spec):
1. Stage special rules (water slow zones, mirror decoys, breathing rooms, map lies)
2. Minimap, lock-on, colorblind palettes, performance pass
