# I.G.O.R. — Character and emotional design

I.G.O.R. (**Inventive Guide Operating Robot**) is the **emotional center** of Proyecto I.G.O.R., not a disposable tutorial voice.

---

## Core principle

**I.G.O.R. is not a menu.** He is the **child’s companion** — present, reactive, and missed when absent.

---

## Emotional goals

- **Lovable**  
- **Endearing**  
- **Funny** (gentle, age-appropriate)  
- **Curious**  
- **Gentle**  
- **Slightly awkward** — relatable, never mocking the player  
- **Encouraging**  
- **Memorable**  
- **Missed when not present**

---

## Feedback behavior (when I.G.O.R. should react)

React when:

- Something **works**  
- Something **fails** (playfully)  
- The child creates a **weird machine**  
- The child **builds** something  
- The child **collects materials**  
- A **Motorling gets a body**  
- The **planet improves**  
- The child **touches** him  
- The child **moves** him  
- The child **tickles** him  

Reactions should be **short**, **readable**, and **optional to skip** where appropriate for repeat play.

---

## Success feedback (examples — localize when implemented)

- “You did it!”  
- “That little machine wants to help.”  
- “Look at it go!”  
- “Your idea worked.”  
- “The planet is a little happier now.”  

(Final strings live in **Localization** when shipped.)

---

## Failure feedback philosophy

- **Never punish.**  
- **Never say “you failed.”**  
- Turn failure into **discovery** and **invitation to try again**.

### Failure feedback examples

- “Interesting… it did something different.”  
- “It has energy, but it needs a way to move.”  
- “That was strange. I liked it.”  
- “Let’s try another shape.”  
- “Maybe it needs wheels.”  

---

## Touch / tablet interaction ideas (future)

- **Tap head** — greeting or thought reaction  
- **Tap antenna** — boing / signal reaction  
- **Tickle** — laughs  
- **Drag I.G.O.R.** — playful complaint  
- **Tap chest tag** — introduces himself  
- **Repeated taps** — silly escalation (with caps to avoid annoyance)  
- **Paint / sticker** interaction — later customization layer  

---

## Important future system: IgorReactionSystem

A dedicated system (name TBD; working title **IgorReactionSystem**) should eventually centralize:

- **Celebration** reactions  
- **Encouragement** reactions  
- **Idle** jokes / ambient life  
- **Tap** reactions  
- **Tickle** reactions  
- **Drag** reactions  
- **Mission** reactions  
- **Construction** reactions  
- **Discovery** reactions  

Goals: **consistent tone**, **no duplicate conflicting lines**, and **easy localization** per reaction category.

---

## Visual alignment

See **[VISUAL_IDENTITY.md](./VISUAL_IDENTITY.md)** for I.G.O.R.’s look (yellow ochre, expressive eyes, nameplate, etc.).

---

## I.G.O.R. Character Prototype v1 (in-engine)

**Not production art** — primitive meshes and simple `StandardMaterial3D` only, aligned loosely with the visual bible until a modeled asset (e.g. Blender **`.glb`**) replaces this rig.

| Item | Location |
|------|----------|
| **Reusable character scene** | `scenes/characters/igor/igor_character.tscn` |
| **Controller script** | `scripts/characters/igor_character.gd` |
| **Optional sandbox** (camera, floor, hint, test UI) | `scenes/characters/igor/igor_character_test.tscn` |
| **Play with I.G.O.R. mode v1** | `scenes/play_with_igor.tscn` · `scripts/play_with_igor.gd` |
| **Main menu** | `scenes/start_screen.tscn` instances **`IgorCharacter`** on the left (scaled); raycast taps forwarded from **`_unhandled_input`**; optional welcome line **`START_IGOR_GREETING`**. |

### Play with I.G.O.R. mode v1

- **Scene:** `scenes/play_with_igor.tscn` — bonding / play mode (not mission-focused). I.G.O.R. is scaled up (~**2×**), framed for tablet, with primitive room meshes.
- **Entry:** Start Screen button **`START_BUTTON_PLAY_WITH_IGOR`** → **`SceneTransition.fade_to_scene`** to this scene; **Back** returns to **`start_screen.tscn`**.
- **Touch:** Same raycast path — scene forwards **`_unhandled_input`** to **`IgorCharacter.handle_viewport_pick()`**.
- **UI buttons:** Randomized localized lines (`IGOR_PLAY_JOKE_*`, `SONG_*`, `HAPPY_*`, `ENCOURAGE_*`) via **`say()`**; **Happy** runs **`react_success()`** then **`say(happy)`**; **Encourage** runs **`react_failure()`** then **`say(encourage)`**; **Toggle** uses **`toggle_debug_touch_zones()`** (zones off by default).
- **Future ideas:** painting / stickers, replaceable parts, more jokes and mini songs, richer emotions — see **[FUTURE_MODULES.md](./FUTURE_MODULES.md)**.

### I.G.O.R. Prototype Interaction v1

- **Raycast-based touch input:** The parent (or sandbox) forwards pointer events to `IgorCharacter.handle_viewport_pick()`. Picking uses the active **`Camera3D`**, **`PhysicsRayQueryParameters3D`**, and **`direct_space_state.intersect_ray()`** — not **`Area3D.input_event`** or **`input_ray_pickable`** on the touch bodies. Touch colliders are **`StaticBody3D`** + **`CollisionShape3D`** on **layer 1**, grouped as `igor_touch_area` with meta **`reaction`** (`head`, `antenna`, `chest`, `belly`, `feet`).
- **Touch zones hidden by default:** Semi-transparent debug meshes (`Debug*TouchVisual`) are created at runtime but **`SHOW_TOUCH_DEBUG_VISUALS`** defaults to **`false`**. Use **`set_touch_debug_visuals_visible(true)`** or the **“Show debug zones”** button in **`igor_character_test.tscn`** when tuning collisions.
- **Cooldown:** Rapid taps are throttled (~**0.25 s**) on the raycast path only; **`react_success()`** / **`react_failure()`** / **`say()`** are not cooldown-gated.
- **Speech:** Localized via **`Localization.t(...)`**; a **`Label3D`** on **`SpeechAnchor`** (billboard toward camera), hides after ~**2** seconds.
- **Debug logging:** **`DEBUG_LOGS`** defaults to **`false`** (no routine **Output** spam).

**Public API (for other scenes later):** `react_success()`, `react_failure()`, `say(message_key)`, `enable_touch_interactions(enabled)`, `set_touch_debug_visuals_visible(show_debug)`, `set_debug_touch_zones_visible(show_zones)`, `toggle_debug_touch_zones()`, `play_joke_motion()`, `play_song_bounce()`, `handle_viewport_pick(event)`.

**Signal:** `igor_reaction_requested(reaction_type, message_key)` — types include `tap_head`, `tap_antenna`, `tap_chest`, `tap_belly`, `tap_feet`, `react_success`, `react_failure`. Copy keys: `IGOR_REACT_*` in **`scripts/localization.gd`**.

**Future plan:** **`play_with_igor.tscn`** already instances this rig; later swap primitive **`VisualRoot`** meshes for an imported **`.glb`** while keeping **`TouchAreas`**, **`SpeechAnchor`**, and the script API where possible. Mission and workshop flows stay on their existing placeholders until product asks for deeper integration.
