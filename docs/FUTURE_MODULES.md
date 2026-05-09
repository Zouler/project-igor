# Future systems and modules — Proyecto I.G.O.R.

Planned or discussed **systems** that are **not** fully implemented in the current MVP. Use this doc to keep prompts and scope aligned.

---

## A. Play with I.G.O.R. mode

A **dedicated mode** where I.G.O.R. appears **large on screen** and the child interacts **directly** with him.

### Shipped in v1

- **Scene:** `scenes/play_with_igor.tscn` · **Script:** `scripts/play_with_igor.gd`  
- Tap **head / antenna / chest / belly / feet** (prototype raycast)  
- UI: **joke**, **song**, **happy**, **encourage** (localized `IGOR_PLAY_*` lines)  
- **Touch-zone** debug toggle for development  
- **Purpose:** **Not mission-focused** — companion / bonding time. See **[IGOR_CHARACTER_DESIGN.md](./IGOR_CHARACTER_DESIGN.md)**.

### Play with I.G.O.R. mode v2 (polish target)

- Cozy play screen / workshop corner composition (tablet-first)
- Reaction categories (Fun / Feelings)
- Randomized lines (avoid immediate repeats)
- Light idle moments (8–12s) when the player is inactive
- Future: paint, stickers, swappable parts, mini songs, richer emotions

### Features (later)

- Move / drag him  
- Tickle; make him laugh  
- Change parts  
- Paint him; add stickers  
- Customize eyes, antenna, hands, colors  
- More jokes, mini songs, emotions  

---

## B. Construction Area

**Separate** from the Laboratory / Workshop.

- Child builds **houses, bridges, structures, facilities** using **wooden blocks / LEGO-like** pieces.  
- Connects to **[WORLD_AND_PROGRESSION.md](./WORLD_AND_PROGRESSION.md)** — civilization growth and unlocks.

---

## C. Scavenger system

- Machines **collect materials** and return them to **camp** / storage.  
- Feeds construction and facility progression.

---

## D. Facility system

- **Buildings** unlock **new machine parts** and **ship components**.  
- Bridges **[MACHINE_SYSTEM.md](./MACHINE_SYSTEM.md)** and **[WORLD_AND_PROGRESSION.md](./WORLD_AND_PROGRESSION.md)**.

---

## E. Living ship system

- The child’s **ship** eventually receives a **spark** and becomes **alive enough** to return safely.  
- Supports **endgame** and **post-game return** to the planet (see world doc).

---

## F. Mission 3 / Light Tower

- **Future mission:** wake the **first light tower** (already teased in Mission Select as locked).  
- **Potential new tool:** **light module** (extends workshop validation and art).  
- Coordinate with **[MISSIONS.md](./MISSIONS.md)** when scope is approved.

---

## Dependency summary

| Module | Ties to |
|--------|---------|
| Play with I.G.O.R. | IGOR_CHARACTER_DESIGN, VISUAL_IDENTITY |
| Construction Area | WORLD_AND_PROGRESSION, GAMEPLAY_VISION |
| Scavenger | WORLD_AND_PROGRESSION, MACHINE_SYSTEM |
| Facility | WORLD_AND_PROGRESSION, MACHINE_SYSTEM |
| Living ship | WORLD_AND_PROGRESSION |
| Mission 3 / Light | MISSIONS, MACHINE_SYSTEM, Localization |
