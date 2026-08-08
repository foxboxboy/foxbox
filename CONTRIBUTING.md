# Contributing

FoxFabric follows the
[official GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html).
Everything below is an addition to it, not a replacement. If something here contradicts the
official guide, the official guide wins and this file is wrong.

## Static typing

Every declaration is typed, including loop variables.

```gdscript
var speed: float = 5.0
for i: int in 10:
```

Not `var speed := 5.0`. `project.godot` turns on `untyped_declaration`, `inferred_declaration`
and the four `unsafe_*` warnings, so inference and untyped access show up in the debugger. A
clean run means zero warnings from FoxFabric code.

When a value arrives as `Variant`, put it in a typed local before using it, rather than casting
at the call site.

```gdscript
var current: float = map.get_data(&"speed", 0.0)
almost(current, 15.0, "...")
```

## Regions

Use these six names for structural sections, in this order:

| Region | Holds |
| --- | --- |
| `Signals` | signal declarations |
| `Variables` | exports first, then public, then private |
| `Built-In Virtuals` | engine callbacks: `_ready`, `_process`, `_enter_tree` |
| `Public API` | methods other code calls |
| `Private` | helpers, `_` prefixed |
| `Abstract Methods` | `@abstract` methods a subclass must implement |

`Virtual Methods` is separate from `Built-In Virtuals` and means hooks a subclass may override
but does not have to, such as `_interact` on `FoxInteractableArea3D`.

A class with real feature areas may use those as region names instead, where structural ones
would be less useful. `FoxAttributeMap` splits into `Data`, `Groups`, `Flags`, `Rules` and
`Hierarchy`, which says more than `Public API` would.

**When not to use them.** Files under about forty lines do not need regions, and a single region
wrapping an entire file never earns its place. Regions are for finding your way around a long
file, not for decoration.

**Spacing.** Four blank lines before `#region`, one after it, and one before `#endregion`.

```gdscript
signal changed(value: float)

#endregion


#region Variables

## The current value.
var value: float = 0.0
```

## Documentation

Every public member gets a `##` comment: classes, signals, exported and public variables,
enums and their constants, and public methods.

Use the crosslink tags rather than plain text, since they become links in both the in-editor
help and the docs site: `[param x]`, `[member x]`, `[method x]`, `[signal x]`, `[constant X]`,
`[ClassName]`. There is no `[class X]` tag.

Reference an inherited member by its owner, or it will not resolve:

```gdscript
## Ensure [member RayCast3D.collide_with_areas] is enabled.
```

Add a `[codeblock]` example to anything whose signature does not explain itself. Every module
that takes a `Variant` payload needs one, because the type says nothing about what to pass.

Documentation is generated from these comments, so `python docs/build_docs.py` must finish with
no errors before a change lands. See `docs/README.txt`.

## Naming

* Files are `snake_case.gd` and match their class: `fox_attribute_map.gd` holds `FoxAttributeMap`
* Every `class_name` starts with `Fox`
* Spatial classes end in `2D` or `3D`, matching the engine

The prefix is not decoration. GDScript has one global namespace for `class_name` and no namespace
support, so `State`, `Effect`, `Price` and `Wallet` would be published into the global scope of
every project that installs FoxFabric. A collision there is not a warning, it stops the other
project from loading. `FoxSocketMap3D` is clunky, and that is the cheaper of the two problems.

## Signals in resources

Connect with a method reference, not a lambda:

```
_pool.depleted.connect(_on_pool_depleted)     # holds an object id
_pool.depleted.connect(func(u): depleted.emit(u))     # holds self
```

A lambda that touches `self` captures it. When a `RefCounted` connects to something it owns, that
closes a cycle, and nothing in the pair is ever freed. Nodes are exempt because they are freed by
hand, but the method form reads better anyway.

## Configuration warnings

Warn about what the engine does not. Before adding one, drop the node in a scene and read what
Godot already says about it. `Area3D` reports a missing shape, `ShapeCast3D` reports a missing
resource, and repeating either makes the node show the same problem twice, worded worse.

Check the claim against the engine before writing it. A warning that says
`force_raycast_update()` needs `enabled` is wrong, the documentation says the opposite, and a
warning that sends people to fix a working setting is worse than no warning at all.

Warnings are covered in `tests/modules/test_configuration_warnings.gd`, in both directions. One
that fires when it should not is as much a bug as one that never fires.

**Refresh them yourself.** Nothing recomputes a warning when the value behind it changes, so
every property a warning reads needs a setter that calls `update_configuration_warnings()`, and
a warning about children needs `child_order_changed` connected under `Engine.is_editor_hint()`.
A warning that only appears after reselecting the node reads as no warning at all.

An inherited property cannot be given a setter. `_set` sees the assignment first, so intercept
it there and defer, since the value has not landed yet:

```gdscript
func _set(property: StringName, _value: Variant) -> bool:
    if property == &"collide_with_areas":
        update_configuration_warnings.call_deferred()
    return false
```

## Editor extras

Gizmos and inspectors live inside the module they belong to, so deleting the module takes them
with it. `addons/foxfabric/foxfabric.gd` registers them and loads each one **by path**:

```gdscript
if not ResourceLoader.exists(path):
    continue
var script: GDScript = load(path) as GDScript
```

Never `preload` one. `preload` resolves when the plugin script is parsed, so a deleted module
would stop the entire plugin from loading rather than dropping one gizmo.

Editor settings go under `foxfabric/`, typed with `add_property_info`. Two limits are not worth
fighting: custom settings cannot carry a description, and they only appear with Advanced turned
on. Both come from `add_property_info` accepting name, type and hint and nothing else.

Never let colour be the only difference between two states. Green against amber is the pair the
two most common forms of colour blindness collapse into one. The socket gizmo nests a second
diamond for an occupied socket so the shape carries the meaning and the colour repeats it.

A gizmo redraws when the editor asks, which is not when your data changes. The node has to call
`update_gizmos()` itself, the same way it calls `update_configuration_warnings()`.

## Line endings

LF, enforced by `.gitattributes`. Godot's doc comment parser leaves the carriage return on the
end of a CRLF line and then cannot join the next line onto it, so a paragraph wrapped across
several `##` lines silently renders as an indented blockquote. It was wrong on 21 pages before
anyone noticed. `docs/build_docs.py` repairs it and warns if it ever has to.

## Module independence

A module may depend on `core` and on nothing else. If two modules need to share something, it
belongs in `core` or it belongs in neither.

`tests/modules/test_module_independence.gd` scans the addon and fails on anything else. The one
allowed exception is listed at the top of that file. Adding to it means the module is no longer
something you can copy out on its own, so it needs a reason.

Modules do not assume what a project means by damage, currency, or interacting. They move a
`Variant` payload and let the receiver decide. A module that reads inside a payload has taken a
position it should not have.

## Tests

New behaviour needs a test in `tests/modules/`. Open `tests/test_runner/test_runner.tscn` and
press F6, or run:

```
godot --headless --path . --script res://tests/terminal/run_all.gd
```

The seed is random each run and printed in the report. Pass it back with `--seed=` to reproduce
a failure. The suite must be green before a change lands.

Some tests deliberately exercise failure paths, so a passing run still prints four warnings. See
`tests/README.txt`.

## Retired code

`deprecated/` and `character/components/trash/` are kept so older projects keep loading. Nothing
new goes in them, they are excluded from the documentation, and they are exempt from everything
above.
