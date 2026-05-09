# Proyecto I.G.O.R. — Architecture Overview

## High-level game flow

1. **Start Screen** — New game, Continue, Settings (language, reset demo).
2. **Story Intro** — Stepped narrative; Skip or advance to the end to continue.
3. **Mission Select** — Choose Mission 1, 2 (when unlocked), or Mission 3 (locked placeholder). Planet progress labels reflect Community completion.
4. **Workshop** — Build the machine for the active mission (parts + slots + Test).
5. **Test Zone** (Mission 1) or **Test Zone Blocks** (Mission 2) — Scripted demo of the machine; no physics.
6. **Community** — Short celebration; planet progress 1% (M1) or 2% (M2); Next returns to Mission Select, Back to Workshop.

Loop back: **Community → Mission Select**; replays go **Mission Select → Workshop** for the chosen mission.

## Main scenes and responsibilities

| Scene | Path | Role |
|--------|------|------|
| Main bootstrap | `scenes/main.tscn` (main scene in project settings) | Loads Start Screen. |
| Start Screen | `scenes/start_screen.tscn` | Entry, save load, settings, routing to Story/Workshop/Community/Test by progress. |
| Story Intro | `scenes/story_intro.tscn` | Localized story steps → Mission Select. |
| Mission Select | `scenes/mission_select.tscn` | Mission choice, 3D map markers, progress copy. |
| Workshop | `scenes/workshop.tscn` | Part/slot building, tutorial hints, routes to correct test scene. |
| Test Zone M1 | `scenes/test_zone.tscn` | Rock-clearing demo. |
| Test Zone M2 | `scenes/test_zone_blocks.tscn` | Block delivery demo. |
| Community | `scenes/community.tscn` | Post-test celebration and navigation. |

Scene changes intended for players go through **`SceneTransition.fade_to_scene(...)`** (fade + `change_scene_to_file`). The main scene uses a direct load once for bootstrap only.

## Autoloads (singletons)

Registered in `project.godot` under `[autoload]`. Access via `/root/<Name>` or global name in GDScript.

### BuildState

- **Role:** Holds the **last completed workshop build** snapshot for the test zones: flags for base/wheels/motor/battery and **`tool_type`** (`"shovel"` or `"cargo_bed"`).
- **Not** long-term progression; reset when starting a fresh build or reset flow. Workshop calls `set_from_workshop` when Test succeeds.

### MissionState

- **Role:** Mission **progression**: `current_mission_id`, `mission_started`, `machine_built`, `test_completed`, `community_unlocked`, `mission_2_completed`, plus localized title/description fields.
- Drives which workshop labels/mission apply, which test scene loads, and Mission Select UI.
- `select_first_mission` / `select_second_mission` reset build progress for that run and clear **BuildState** via reset.

### SaveManager

- **Role:** Persist **`user://igor_demo_save.cfg`**: locale + mission fields from **MissionState**.
- Load on Start Screen `_ready`; save on mission milestones and locale change.
- **Reset Demo** deletes the save file then saves again so **language is kept** but mission progress is cleared.

### Localization

- **Role:** In-memory `translations` dictionary (`en`, `es`); **`t("KEY")`** for all user-facing strings.
- **`locale_changed`** signal for UI refresh.
- **`set_locale`** triggers **SaveManager.save_game** so language persists.

### SceneTransition

- **Role:** Full-screen **ColorRect** fade; **`fade_to_scene(path)`** and automatic **fade_in** on `scene_changed`.
- Lives for the whole app; do not duplicate fade logic in scenes for normal navigation.

## How Mission 1 works

- **Mission id:** `clear_first_path`.
- **Workshop:** Shovel part visible; cargo bed hidden. Player fills slots; **Test** validates tool **`shovel`** via **IgorGuide** / **BuildState**.
- **Test:** `test_zone.tscn` — scripted machine clears rocks; then **Continue** → **Community** (1% copy).

## How Mission 2 works

- **Unlock:** **MissionState.community_unlocked** after Mission 1 Community.
- **Mission id:** `carry_first_blocks`.
- **Workshop:** Cargo bed visible; shovel hidden. **Test** requires **`cargo_bed`**.
- **Test:** `test_zone_blocks.tscn` — scripted block pickup/delivery; **Continue** → **Community** (2% copy).

## How Workshop adapts per mission

- **`MissionState.current_mission_id`** selects mission label keys, tutorial copy (shovel vs cargo steps), and **`_apply_mission_tool_parts_visibility`** (which tool part is visible and ray-pickable).
- **`IgorGuide`** checks **`current_mission_id`** and **`tool_type`** on the placed tool part for validation and success messages.

## BuildState vs MissionState

| | **BuildState** | **MissionState** |
|--|----------------|------------------|
| **Purpose** | Snapshot of **one** workshop build for the next test scene. | **Campaign** state: which mission, what’s unlocked, what’s completed. |
| **Lifetime** | Cleared/reset when appropriate for a new build attempt. | Persisted (with limits) via **SaveManager**. |
| **Typical use** | `tool_type`, `has_*` for visuals in test zones. | Routing, UI, unlocks, `current_mission_id`. |

## How SaveManager persists progress

- **ConfigFile** at `user://igor_demo_save.cfg`.
- **settings:** `locale`
- **mission:** `mission_started`, `machine_built`, `test_completed`, `community_unlocked`, `mission_2_completed`, `current_mission_id` (only `clear_first_path` / `carry_first_blocks` are written today).
- Autoloads are resolved via **`get_node_or_null("/root/...")`** — not `Engine.get_singleton` — for reliable save/load.

## How Localization is used

- Scripts call **`Localization.t("KEY")`** (or hold a reference to the autoload).
- **`Localization.set_locale("en"|"es")`** updates **`current_locale`** and emits **`locale_changed`**.
- Full key list and workflow: see **[LOCALIZATION.md](./LOCALIZATION.md)**.

## No physics (yet)

- Gameplay and tests use **tweens** and direct transforms, not rigid bodies or physics queries.
- Project may still list a physics engine in settings; **do not** rely on physics for MVP loops.

## Visuals (current)

- **Primitive meshes** and simple materials in scenes; in-engine look is still placeholder. Target art direction is documented in **[VISUAL_IDENTITY.md](./VISUAL_IDENTITY.md)**; governance / approval reminders in **[VISUAL_IDENTITY_TODO.md](./VISUAL_IDENTITY_TODO.md)**.
