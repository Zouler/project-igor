# Machine system — Motorlings and construction logic

How **machines** are conceptualized in Proyecto I.G.O.R.

---

## Core idea

**Machines are not dead tools.** They are **bodies** given to living **Motorlings / Spark Cores**. Building a machine is an act of **care** and **partnership**.

---

## Motorlings / Spark Cores

- **Living motor-like creatures** — consciousness tied to energy / “spark.”  
- **Have eyes / personality / spark** — expressiveness matters.  
- **Hatch** from mechanical shells / capsules (egg-like beats).  
- Have **energy and personality** but **no body** until the child builds one.  
- Need the **child** to assemble a body so they can **help** the world.  
- **Friendly name:** Motorlings / *motorcitos* (localization-friendly).  
- **Technical name:** Spark Cores / *Núcleos Chispa*.

---

## Simple classification rules (parts → function)

Design vocabulary for combining parts (exact implementation evolves in Workshop / future lab):

| Part role | Effect |
|-----------|--------|
| **Base** | Body / structure / attachment foundation |
| **Wheels / legs / rollers** | Movement modality |
| **Motor** | Force / drive |
| **Battery** | Energy supply |
| **Tool** | **Job** — defines primary world interaction |
| **Cargo bed** | **Carrying** capacity |
| **Light module** | **Illumination** (future — ties to light towers) |
| **Brush** | **Cleaning** |
| **Roller** (tool) | **Road / flattening** |
| **Shovel / drill** | **Digging / clearing** |

The **MVP** implements a subset: base, wheels, motor, battery, and **shovel** or **cargo_bed** as the tool slot.

---

## Initial machine families (target roster)

Conceptual families from part combinations:

- **Simple Vehicle** — base + wheels + motor + battery; **no** useful tool (may still move / delight).  
- **Digger** — vehicle + shovel / drill.  
- **Carrier** — vehicle + cargo bed.  
- **Sweeper** — vehicle + brush.  
- **Roller** — vehicle + roller tool.  
- **Builder** — vehicle + arm / building tool.  
- **Scavenger** — vehicle + collector / storage tool.  
- **Lightbot** — vehicle + light module.

---

## Random / weird machine behavior

**Not every build must be “optimal.”** Odd combinations should still **react** — vibration, spin, silly motion, or I.G.O.R. commentary.

### Examples

- **Wheels + motor + base** → little car; if **no roads**, it may **circle or wander**.  
- **Motor + battery** without wheels → **vibrates** in place.  
- **Cargo bed** without motor → **static cart**.  
- **Too many wheels, no tool** → **fast silly vehicle**.  
- **Wrong tool for terrain** → **playful attempt**, little or no progress, **no punishment**.

---

## Design rule

**Failure should be playful and informative, not punitive.** Align with **[IGOR_CHARACTER_DESIGN.md](./IGOR_CHARACTER_DESIGN.md)** for copy and tone.

---

## Implementation note (MVP)

Current **Workshop** validates a **fixed slot order** and **one tool type per mission** (shovel vs cargo bed). This document describes the **design space** for expanding validation, visuals, and test zones as more tools exist.
