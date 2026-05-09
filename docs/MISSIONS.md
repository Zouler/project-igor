# Mission design notes — Proyecto I.G.O.R.

## Mission 1 — Clear the first path

| Field | Detail |
|--------|--------|
| **Title (keys)** | `MISSION_1_TITLE` / workshop `WORKSHOP_MISSION_LABEL` |
| **Required tool** | **`shovel`** (`tool_type` on shovel part) |
| **Workshop flow** | Base → wheels → motor → battery → **shovel** in tool slot; **Test** → `test_zone.tscn`. |
| **Test zone objective** | Scripted run: machine clears rocks / opens path (Mission 1 test zone). |
| **Community result** | **Planet progress 1%** (`COMMUNITY_PROGRESS` / related copy). |

## Mission 2 — Carry the first blocks

| Field | Detail |
|--------|--------|
| **Title (keys)** | `MISSION_2_TITLE` / `WORKSHOP_MISSION_LABEL_M2` |
| **Required tool** | **`cargo_bed`** |
| **Workshop flow** | Same slot pattern; **cargo bed** in tool slot; **Test** → `test_zone_blocks.tscn`. |
| **Test zone objective** | Scripted run: pick up blocks and deliver to zone (0/3 → 3/3). |
| **Community result** | **Planet progress 2%** (`MISSION_2_COMMUNITY_PROGRESS` / related copy). |

**Unlock:** Mission 2 becomes available after Mission 1 community progress unlocks **`community_unlocked`** in **MissionState**.

## Mission 3 — Placeholder (locked)

| Field | Detail |
|--------|--------|
| **Title** | Wake the first light tower (`MISSION_3_TITLE`) |
| **Status** | **Locked / future** — no gameplay, no new parts, not unlocked after Mission 2. |
| **Purpose** | Story hook: sleeping light tower; future **light restoration** mission when design allows. |

UI uses dedicated locked copy (e.g. `MISSION_3_LOCKED_MESSAGE`) and a **Mission Select** marker (primitive “tower” visual).

---

## Rules for adding future missions

1. **Localization** — Add all new user-facing strings as keys in **`scripts/localization.gd`** (`en` and `es`); never ship hardcoded visible text.
2. **MissionState** — Extend with new mission id(s), unlock rules, completion flags, and any helpers (`select_*`, `mark_*`, `refresh_localized_titles`, etc.).
3. **SaveManager** — If progress must persist, add fields to save/load in **`scripts/save_manager.gd`** and keep migration safe (defaults for missing keys).
4. **Mission Select** — New card(s), markers, routing; keep layout readable (mobile / children).
5. **Workshop** — Prefer **reusing** the same workshop scene with mission branches (tool visibility, `IgorGuide`, labels) before forking a second workshop scene.
6. **Test zone** — Add a **mission-specific** scene only when the demo cannot share an existing test zone; keep **no physics** unless the project explicitly moves to physics later.
