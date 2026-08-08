# FoxFabric

A library of reusable, self-contained gameplay systems for Godot 4.

Every module stands on its own. Copy the whole `addons/foxfabric` folder or pull out
the single directory you need. Most of them route arbitrary `Variant` payloads instead
of hardcoding what damage, currency, or interaction mean, so a module never has to know
anything about your project.

## Modules

The data and logic modules have no spatial dependency and work in 2D, 3D, or plain UI.
The rest are listed with what they target.

| Module | Works in | Description |
| --- | --- | --- |
| `core` | any | Rudimentary and abstract classes, utilities, and generic helpers used universally across the FoxFabric framework. |
| `attribute_map` | any | A recursive, hierarchical data structure for safely managing, clamping, and querying dynamic entity statistics and state variables. |
| `effect` | any | A memory-safe Flyweight architecture for managing the lifecycle, stacking, and interval ticking of temporary gameplay modifiers (buffs and debuffs) without SceneTree bloat. |
| `state_machine` | any | A node-based Finite State Machine (FSM) architecture for separating complex entity logic (like player movement or enemy AI) into discrete, manageable, and isolated state nodes. |
| `shop` | any | A highly abstracted, decoupled transaction system. Instead of relying on hardcoded "number" currencies, it routes arbitrary data between generic Wallets and Shops, allowing currency to be anything from integers to physical items. |
| `socket` | 2D and 3D | A spatial occupancy and reparenting system that allows for safely attaching nodes to defined "seats." |
| `damage` | 3D | A completely decoupled, physics-based data routing pipeline. It uses a network of spatial deliverers (FoxHitArea3D, FoxHitRayCast3D, FoxHitShapeCast3D) and receivers (FoxHurtArea3D) to transport arbitrary Variant payloads across the game world without hardcoding damage or combat logic. |
| `interaction` | 3D | A raycast-driven focus and activation pipeline. FoxInteractionRayCast3D focuses and triggers FoxInteractableArea3D volumes, which emit an arbitrary Variant context so the initiator decides what interacting actually means. |
| `aim_gimbal` | 3D | A pure mathematical hinge for accumulating 2D input into clamped, gimbal-lock-safe pitch and yaw rotations. |
| `zoom_spring_arm` | 3D | An extended SpringArm3D component for camera controllers. It replaces standard length adjustments with smooth, frame-independent zoom interpolation, clamp limits, precise signal emissions for UI/visibility toggling, and built-in multiplayer authority checks. |
| `physics_dragging` | 3D | Manipulates a RigidBody3D by applying localized forces and torques to pull it toward a target node. Stiffness, damping, and force limits live in swappable FoxPhysicsDragProfile resources. |
| `view_model` | 3D | A SubViewportContainer that keeps its SubViewport matched to the main viewport size, for rendering first person view models in a layer separate from the world. |
| `world_environments` | 3D | Provides some generic world environments, skyboxes, etc. |
| `character` | 3D | Motors, abilities, and states for driving a CharacterBody3D, plus the mannequin and accessory assets used by the demos. Under heavy refactor and not representative of the rest of the library. |
| `deprecated` | n/a | Graveyard for old code and retired prototypes. |

Each description above is the same text as that module's own `README.txt`.

Every class ships with full `##` documentation so it renders in Godot's built-in help,
and every module has an editor icon.

## Install

Copy `addons/foxfabric/` into your project's `addons/` folder, then enable FoxFabric
under Project Settings > Plugins.

Requires Godot 4.7 or newer. The demos assume the Jolt physics engine.

## Demos

`foxfabric_demos/` has a scene per module. They are the quickest way to see what
something does before reading it.

## Status

Version 0.1. This is a personal library first, so expect churn.

The `character` module needs a heavy refactor and does not reflect how the rest of the
library is written. Parts of it still hardcode things they should not, like a `crouch()`
on the hitbox. Read any other module for the intended style.

`docs/` is an experiment that generates a browsable web version of the API using Godot's
own documentation tooling. The checked in output is stale. Regenerate it with `make html`
inside `docs/web`.

There are no automated tests yet. The demo scenes act as the smoke tests.

The roadmap is in [TODO.txt](TODO.txt).

## License

MIT, see [LICENSE](LICENSE). Use it in anything, commercial or not.

The stylized sky shader in `world_environments` is not mine. It is from GDQuest, via
[godotshaders.com](https://godotshaders.com/shader/stylized-sky/).
