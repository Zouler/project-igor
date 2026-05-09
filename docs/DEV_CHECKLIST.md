# Development checklist — before every commit

Use this list before merging or pushing gameplay/UI changes.

## Manual playtest

- [ ] Run the game from **Start Screen** (project main scene flow).
- [ ] **Start** — new game into Story Intro → Mission Select → Mission 1 path works.
- [ ] **Continue** — resumes at the correct scene for saved progress.
- [ ] **Reset Demo** — mission progress resets; **language unchanged**.
- [ ] **Language** — switch **EN / ES** in Settings; UI updates; restart and confirm persistence.
- [ ] **Story Intro** — **Skip** and final button reach Mission Select.
- [ ] **Mission Select** — cards, locked M3, back to Start; M1/M2 enter Workshop correctly.
- [ ] **Mission 1** — full loop: Workshop → Test Zone → Community → Mission Select.
- [ ] **Mission 2** — full loop (after M1 unlock): Workshop → Test Zone Blocks → Community → Mission Select.
- [ ] **Community** — **Back** to Workshop, **Next** to Mission Select.

## Editor / output

- [ ] **Output** panel: no new errors or warnings that indicate broken scenes or scripts.
- [ ] No new **hardcoded** user-facing text (use **`Localization.t("KEY")`**).
- [ ] No **`Node3D.modulate`** usage (use **`Control.modulate`** only where appropriate for UI).
- [ ] No noisy **`print`** in normal play — keep logs behind **`DEBUG_LOGS`** (or equivalent) set to **`false`**.
- [ ] No **external assets** added unless the task explicitly allows them.

## Optional quick load

- [ ] Open project in Godot 4.x; confirm **no parse errors** and scenes load.
