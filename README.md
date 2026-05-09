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

| Doc | Description |
|-----|-------------|
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Flow, scenes, autoloads, BuildState vs MissionState, save, localization overview |
| [docs/MISSIONS.md](docs/MISSIONS.md) | Mission 1 & 2 design notes, Mission 3 placeholder, rules for future missions |
| [docs/LOCALIZATION.md](docs/LOCALIZATION.md) | Keys, `t("KEY")`, save behavior for language |
| [docs/DEV_CHECKLIST.md](docs/DEV_CHECKLIST.md) | Pre-commit manual test checklist |
| [docs/VISUAL_IDENTITY_TODO.md](docs/VISUAL_IDENTITY_TODO.md) | Placeholder: art direction not finalized |

## License / credits

Add here if applicable.
