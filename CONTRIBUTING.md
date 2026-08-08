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

## Signals in resources

Connect with a method reference, not a lambda:

```
_pool.depleted.connect(_on_pool_depleted)     # holds an object id
_pool.depleted.connect(func(u): depleted.emit(u))     # holds self
```

A lambda that touches `self` captures it. When a `RefCounted` connects to something it owns, that
closes a cycle, and nothing in the pair is ever freed. Nodes are exempt because they are freed by
hand, but the method form reads better anyway.

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
