# Localization — Proyecto I.G.O.R.

## Locales

- **English (`en`)** is the **default** fallback inside **`Localization.t()`** if a key is missing in the active locale.
- **Spanish (`es`)** is fully supported for the same keys.

## Rules for user-facing text

- **All visible text** should go through **`Localization.t("KEY")`** from the **Localization** autoload (`scripts/localization.gd`).
- **Do not** hardcode user-visible strings in GDScript that players see (buttons, labels, hints, 3D label text set at runtime).
- **Scene files (`.tscn`)** may contain placeholder text for editor layout; runtime scripts should **overwrite** with **`t("KEY")`** in `_ready` / refresh handlers so the correct language shows in game.

## Where translations live

- **Single source:** `scripts/localization.gd` — nested dictionary **`translations`** with top-level keys **`"en"`** and **`"es"`**, each a `Dictionary` of **`"KEY" -> "string"`**.

No external CSV or PO files in the current MVP.

## How to add a new key

1. Add the English string under **`translations["en"]["YOUR_KEY"]`**.
2. Add the Spanish string under **`translations["es"]["YOUR_KEY"]`** (keep meaning aligned with English).
3. Use **`_loc.t("YOUR_KEY")`** or **`Localization.t("YOUR_KEY")`** in code.
4. If the UI must update when the player changes language in Settings, connect **`locale_changed`** and refresh labels (pattern used in Start Screen, Mission Select, Workshop, test zones, Community as needed).

## Existing locale behavior

- **Selected language** is stored in the save file (**SaveManager** → `settings/locale`).
- **On startup**, Start Screen calls **`SaveManager.load_game()`**, which applies **`set_locale`** so **language persists after restart**.
- **Reset Demo** clears mission save data but **re-saves** with the **current** locale — **language is kept**.

## Related docs

- Architecture: **[ARCHITECTURE.md](./ARCHITECTURE.md)**
- Pre-commit checks: **[DEV_CHECKLIST.md](./DEV_CHECKLIST.md)**
