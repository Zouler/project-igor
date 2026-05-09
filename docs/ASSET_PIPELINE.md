# Asset pipeline — Proyecto I.G.O.R.

This document describes the **lightweight asset pipeline** used while the project is still using placeholder primitives and early imported models.

## Incoming assets (raw)

- **Meshy raw assets** go under: `assets/incoming/meshy/`
- **Raw files should not be edited directly** (treat as source-of-truth dumps).
- Keep filenames stable (version via folder/name changes, not by overwriting files).

## Preferred format

- **`.glb`** is the preferred format for 3D model import into Godot.

## Import testing (required first step)

Before any model replaces a prototype:

- Create a dedicated **import test scene** that only:
  - instances the raw model
  - adjusts transform **in the test scene only** (scale/orientation/position)
  - adds simple lighting + floor + scale reference
  - prints a simple audit (mesh counts, surfaces/material slots, approximate bounds)

For I.G.O.R.:

- Raw GLB path: `assets/incoming/meshy/igor/igor_raw.glb`
- Import test scene: `scenes/characters/igor/igor_model_import_test.tscn`
- Audit script: `scripts/tools/igor_model_import_audit.gd`

### I.G.O.R. import tests

- `igor_raw.glb`: first raw import, one near-white material, no textures found (per audit)
- `igor_raw_textured.glb`: second textured Meshy export, pending audit via `igor_model_textured_import_test.tscn`

## Approved/cleaned assets

After an import passes visual/audit checks, approved models move to:

- `assets/characters/igor/models/`

Supporting assets can be placed in:

- `assets/characters/igor/materials/`
- `assets/characters/igor/textures/`

## Next step (after import test)

Create a **wrapper scene** for the model (still separate from gameplay):

- instances the cleaned model
- adds touch zones / interaction helpers (later step)
- keeps prototype scenes intact until replacement is approved

## Motorling Meshy imports

- **Source (typo folder, keep untouched for now):** `assets/incomming/meshy/motorlings/`
- **Corrected safe folder:** `assets/incoming/meshy/motorlings/`
- Each motorling is copied into its own folder:
  - `assets/incoming/meshy/motorlings/motorling_01/`
  - `assets/incoming/meshy/motorlings/motorling_02/`
  - `assets/incoming/meshy/motorlings/motorling_03/`
  - `assets/incoming/meshy/motorlings/motorling_04/`
- **GLBs are renamed (copies only)** to short names:
  - `motorling_01_raw.glb`, `motorling_02_raw.glb`, `motorling_03_raw.glb`, `motorling_04_raw.glb`
- **JPG texture filenames are preserved** (GLBs may reference the original JPG names internally).
- Do **not** delete the typo folder until import tests confirm textures/materials still link correctly.

