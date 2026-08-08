# 🦊 FoxFabric

**Drop-in, decoupled 3D gameplay modules for Godot 4.**

A personal library of the reusable systems I keep rebuilding — combat, stats, status
effects, cameras, interaction — written so they never assume anything about your game.
Damage, currency, and interaction all move arbitrary `Variant` payloads, so a module
never needs to know what "health" or "gold" means in your project.

Take one folder or take all of them. Nothing here depends on the rest of it.

---

## Modules

| Module | What it does |
| --- | --- |
| `core` | Base classes (`FoxNode`, `FoxNode3D`, `FoxResource`) and math primitives — `FoxBoundedValue`, `FoxModifiableStat`, `FoxStatPool` |
| `attribute_map` | Recursive blackboard for entity data, stacked flags, and rules that propagate through a node hierarchy |
| `effect` | Flyweight buffs and debuffs with stacking modes, interval ticking, and save/load — no node per effect |
| `damage` | Hit/hurt pipeline. `FoxHitArea3D`, `FoxHitRayCast3D`, and `FoxHitShapeCast3D` deliver payloads to `FoxHurtArea3D` |
| `interaction` | Raycast-driven "press E" pipeline, fully decoupled from what interacting means |
| `state_machine` | Node-based FSM for splitting entity logic into isolated states |
| `shop` | Wallets, prices, and catalogs where currency can be an item, not just a number |
| `socket` | Spatial occupancy and safe reparenting — seats, mounts, attachment points (2D + 3D) |
| `aim_gimbal` | Clamped, gimbal-lock-safe pitch/yaw accumulation for cameras and turrets |
| `zoom_spring_arm` | `SpringArm3D` with smooth frame-independent zoom and signals for fading the model |
| `physics_dragging` | Grab and haul `RigidBody3D`s with tunable drag profiles |
| `view_model` | First-person viewmodel container |
| `world_environments` | Prebuilt stylized and mobile `WorldEnvironment` setups |
| `character` | Motors, abilities, and character states — **under heavy refactor, see Status** |

Every class ships with full `##` documentation, so it renders properly in Godot's
built-in help. Every module has an editor icon.

---

## Install

1. Copy `addons/foxfabric/` into your project's `addons/` folder.
2. Enable **FoxFabric** in `Project → Project Settings → Plugins`.

Requires **Godot 4.7+**. The demos assume the **Jolt** physics engine.

---

## Demos

`foxfabric_demos/` has a scene per module. They're the fastest way to see what a
module does before reading it.

---

## Status

This is version `0.1` and it is a personal library first — expect churn.

- **`character/` needs a heavy refactor** and is not representative of the rest.
  Its modules still hardcode things they shouldn't (a `crouch()` on the hitbox, for
  one). Treat everything else as the reference for how a module should look.
- **`docs/` is an experiment.** It generates a browsable web version of the library's
  API using Godot's own doc tooling. The checked-in output is stale and the build
  directory isn't tracked — regenerate with `make html` in `docs/web`.
- No automated tests yet. The demo scenes are the smoke tests.

Roadmap lives in [TODO.txt](TODO.txt).

---

## License

MIT — see [LICENSE](LICENSE). Use it in anything, commercial or not.

The stylized sky shader in `world_environments/` is **not** mine — it's from GDQuest,
via [godotshaders.com](https://godotshaders.com/shader/stylized-sky/).
