# FoxFabric

<p align="center">
  <a href="https://foxfabric-godot.readthedocs.io">
    <img src="icons/full_logo.svg" width="400" alt="FoxFabric logo">
  </a>
</p>

## Modular systems for Godot 4

**FoxFabric is a lightweight, general purpose library for Godot 4.** Built from independent
minimalistic modules.

## Modules

The data and logic modules have no spatial dependency and work in 2D, 3D, or plain UI.
The rest are listed with what they target.

| Module | Works in | Description |
| --- | --- | --- |
| `core` | any | The base classes the other modules extend, and the maths helpers they share. |
| `attribute_map` | any | Holds an entity's data in a tree. Rules and flags on a parent reach every map beneath it. |
| `effect` | any | Buffs and debuffs that stack, expire, and tick on a timer. One resource describes the effect, and a manager runs the active ones. |
| `state_machine` | any | States as child nodes. The machine forwards process, physics, and input to whichever one is current. |
| `shop` | any | Wallets, prices, and catalogues for buying things. A price decides for itself whether a wallet can pay. |
| `json` | any | Reads and writes JSON that keeps its Godot types. A file carries its format, and an older one migrates forward on read. |
| `socket` | 2D and 3D | Named seats a node attaches to, one occupant each. Attaching reparents and snaps to the marker. |
| `damage` | 2D and 3D | Hit areas, raycasts, and shapecasts that deliver a payload to hurt areas. |
| `interaction` | 2D and 3D | A raycast that tracks what it is pointing at, and areas that answer when you interact with them. |
| `aim_gimbal` | 3D | Turns mouse or stick movement into pitch and yaw, with limits on each. Pitch and yaw are separate nodes. |
| `zoom_spring_arm` | 3D | A SpringArm3D that eases to a new length instead of snapping, between a minimum and maximum. Emits when it reaches either end. |
| `physics_dragging` | 2D and 3D | Pulls a RigidBody towards a target node with forces and torque. Stiffness and damping live in a resource. |
| `view_model` | 3D | A SubViewportContainer that keeps its SubViewport the same size as the main one, for first person hands and weapons. |
| `world_environments` | 3D | Ready-made WorldEnvironment scenes, including a stylized sky and a cheaper one for mobile. |
| `character` | 3D | Motors, abilities, and states for driving a CharacterBody3D, plus the mannequin and accessory assets the demos use. Under heavy refactor. |

Each description above is the same text as that module's own `README.txt`.

Every class ships with full `##` documentation, so it renders in Godot's built-in help.

## Install

Copy `addons/foxfabric/` into your project's `addons/` folder, then enable FoxFabric
under Project Settings > Plugins.

Requires Godot 4.7 or newer. The demos assume the Jolt physics engine.

## Demos

`demos/` has runnable scenes. They are the quickest way to see what something does before
reading it.

## Documentation

The class reference is published at
[foxfabric-godot.readthedocs.io](https://foxfabric-godot.readthedocs.io). It is the same content
as Godot's built-in help.

To build it yourself:

```
pip install sphinx sphinx-rtd-theme
python docs/build_docs.py --open
```

See [docs/README.txt](docs/README.txt) for the steps it runs.

## Status

Version 0.1. This is a personal library first, so expect things to change a looooootttt.

The `character` module needs a heavy refactor and does not reflect how the rest of the
library is written. Parts of it still hardcode things they should not, like a `crouch()`
on the hitbox. Read any other module for the intended style.

## Tests

`tests/` holds a self-contained suite covering every module except `character`. It needs no
addon and no install, so a fresh clone can run it straight away.

**In the editor:** open `tests/test_runner/test_runner.tscn` and press F6. Results render on screen and in
the Output panel. Select the `TestRunner` node to filter to one module or change the seed.

**From the command line**, for CI:

```
./tests/run_tests.sh
```

The wrapper locates Godot, and does a one-time import pass if `.godot/` is missing. Calling
Godot directly works too, but only once the project has been imported at least once, since
`--script` skips the import pass and without it no `class_name` resolves:

```
godot --headless --path . --script res://tests/terminal/run_all.gd
```

It exits 0 on success and 1 on any failure. Some tests deliberately drive failure paths, so
warnings appear during a passing run. Read the report at the bottom, not the warnings above it.
See [tests/README.txt](tests/README.txt) for how to add a suite.

The roadmap is in [TODO.txt](TODO.txt), and the style guide is in [CONTRIBUTING.md](CONTRIBUTING.md).

## License

MIT, see [LICENSE](LICENSE). Use it in anything, commercial or not.

The stylized sky shader in `world_environments` is not mine. It is from GDQuest, via
[godotshaders.com](https://godotshaders.com/shader/stylized-sky/).
