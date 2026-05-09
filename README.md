# Proyecto I.G.O.R.

**Inventive Guide Operating Robot** — a Godot 4 **3D children’s game** (ages 5+) about a young inventor helping **I.G.O.R.** rebuild a small mechanical planet by giving bodies to **Motorlings** / Spark Cores.

## Current status (MVP)

The **core loop** is playable: **Start Screen → Story Intro → Mission Select → Workshop → Test Zone (Mission 1) or Test Zone Blocks (Mission 2) → Community**, with **English/Spanish** localization, **local save**, and **scene transitions**. **Mission 3** exists as a **locked** story hook only. **Physics is not** used for gameplay yet; visuals are largely **primitive meshes**.

## Requirements

- **Godot 4.x** (project targets **4.6**, **Mobile** renderer — see `project.godot`).
- Clone the repo and open the folder as a project in the Godot editor.

## Run

1. Open the project in Godot.
2. Press **Play** (main scene loads the start flow).
3. Use **Start Screen** for new game, **Continue**, and **Settings** (language / reset demo).

## Documentation

### Vision and design

| Doc | Description |
|-----|-------------|
| [docs/VISUAL_IDENTITY.md](docs/VISUAL_IDENTITY.md) | Visual identity bible v1 (pillars, I.G.O.R., world, UI, materials) |
| [docs/VISUAL_IDENTITY_TODO.md](docs/VISUAL_IDENTITY_TODO.md) | Governance note + link to the evolving visual bible |
| [docs/GAMEPLAY_VISION.md](docs/GAMEPLAY_VISION.md) | Core loop, workshop vs construction, tablet-first goals |
| [docs/WORLD_AND_PROGRESSION.md](docs/WORLD_AND_PROGRESSION.md) | Planet map, terrain roles, civilization, ship endgame tone |
| [docs/IGOR_CHARACTER_DESIGN.md](docs/IGOR_CHARACTER_DESIGN.md) | Emotional design, feedback philosophy, future IgorReactionSystem |
| [docs/MACHINE_SYSTEM.md](docs/MACHINE_SYSTEM.md) | Motorlings, parts taxonomy, machine families, playful failure |
| [docs/FUTURE_MODULES.md](docs/FUTURE_MODULES.md) | Play-with-I.G.O.R., construction, scavenger, facilities, ship, M3 |

### Technical and process

| Doc | Description |
|-----|-------------|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Flow, scenes, autoloads, BuildState vs MissionState, save, localization overview |
| [docs/MISSIONS.md](docs/MISSIONS.md) | Mission 1 & 2 design notes, Mission 3 placeholder, rules for future missions |
| [docs/LOCALIZATION.md](docs/LOCALIZATION.md) | Keys, `t("KEY")`, save behavior for language |
| [docs/DEV_CHECKLIST.md](docs/DEV_CHECKLIST.md) | Pre-commit manual test checklist |

## License / credits

Add here if applicable.
