# Contributing

FoxFabric follows the
[official GDScript style guide](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html).
Everything below is an addition to it. Where the two disagree, the official guide wins and this
file is wrong.

## Static typing

* Every declaration is typed, including loop variables
* A `Variant` goes into a typed local before it is used

```gdscript
var speed: float = 5.0
for i: int in 10:
var current: float = map.get_data(&"speed", 0.0)
```

`project.godot` enables `untyped_declaration`, `inferred_declaration` and the four `unsafe_*`
warnings, so `var speed := 5.0` shows up in the debugger. A clean run has zero warnings from
FoxFabric code.

## Regions

Six names for structural sections, in this order:

| Region | Holds |
| --- | --- |
| `Signals` | signal declarations |
| `Variables` | exports first, then public, then private |
| `Built-In Virtuals` | engine callbacks: `_ready`, `_process`, `_enter_tree` |
| `Public API` | methods other code calls |
| `Private` | helpers, `_` prefixed |
| `Abstract Methods` | `@abstract` methods a subclass must implement |

* `Virtual Methods` is a seventh, for hooks a subclass may override but need not, like `_interact`
* A class with real feature areas may use those instead: `FoxAttributeMap` splits into `Data`,
  `Groups`, `Flags`, `Rules`, `Hierarchy`
* Files under about forty lines do not need regions
* Four blank lines before `#region`, one after it, one before `#endregion`

## Documentation

* Every public member gets a `##` comment: classes, signals, exported and public variables, enums
  and their constants, public methods. Private `_members` get `#`
* Use crosslink tags, not plain text: `[param x]`, `[member x]`, `[method x]`, `[signal x]`,
  `[constant X]`, `[ClassName]`. There is no `[class X]` tag
* An inherited member needs its owner: `[member RayCast3D.collide_with_areas]`
* A class summary says what the class **is**, as a noun phrase: `A 2D area that delivers a
  payload to overlapping nodes.`
* The description below it opens by naming the class: `[FoxHitArea2D] can act passively via…`
* Anything taking a `Variant` payload needs a `[codeblock]` example
* A class a guide walks through links back on the last line of its comment:
  `## @tutorial(Title): https://…`

Read the Docs cannot run Godot, so the pages under `docs/web/` are committed. Change a `##`
comment and regenerate them in the same commit. Both of these run in CI:

```
python docs/build_docs.py --skip-html
python docs/check_doc_style.py
```

## Naming

* Files are `snake_case.gd` and match their class: `fox_attribute_map.gd` holds `FoxAttributeMap`
* Every `class_name` starts with `Fox`
* Spatial classes end in `2D` or `3D`, matching the engine

GDScript has one global namespace for `class_name`. Without the prefix, `State`, `Effect`, `Price`
and `Wallet` would be published into every project that installs FoxFabric, and a collision there
stops the other project from loading.

## Signals in resources

Connect with a method reference:

```gdscript
_pool.depleted.connect(_on_pool_depleted)
_pool.depleted.connect(func(u): depleted.emit(u))     # captures self
```

A lambda touching `self` captures it. When a `RefCounted` connects to something it owns, that
closes a cycle and neither is ever freed. Nodes are exempt, being freed by hand.

## Configuration warnings

* Warn about what the engine does not. `Area3D` already reports a missing shape, `ShapeCast3D` a
  missing resource
* Check the claim against the engine first. A warning that sends someone to fix a working setting
  is worse than no warning
* Every property a warning reads needs a setter calling `update_configuration_warnings()`
* A warning about children needs `child_order_changed` connected under `Engine.is_editor_hint()`
* Cover both directions in `tests/modules/test_configuration_warnings.gd`

An inherited property cannot be given a setter. Intercept it in `_set` and defer, since the value
has not landed yet:

```gdscript
func _set(property: StringName, _value: Variant) -> bool:
	if property == &"collide_with_areas":
		update_configuration_warnings.call_deferred()
	return false
```

## Editor extras

* Gizmos and inspectors live in the module they belong to. `foxfabric.gd` loads each one by path
* Never `preload` a module's editor script. `preload` resolves when the plugin is parsed, so one
  deleted module stops the whole plugin from loading
* Editor settings go under `foxfabric/`, typed with `add_property_info`. They cannot carry a
  description and only appear with Advanced on
* Gizmos redraw when the editor asks. Call `update_gizmos()` yourself, the same way you call
  `update_configuration_warnings()`
* Never let colour be the only difference between two states. The socket gizmo adds a second
  diamond when occupied

## Line endings

LF, enforced by `.gitattributes`. A CRLF line breaks Godot's doc comment parser: wrapped
paragraphs render as indented blockquotes. It was wrong on 21 pages before anyone noticed.

YAML files must not contain tabs. Godot re-saves files open in its script editor using tabs, which
breaks `.readthedocs.yaml`. CI checks for it.

## Module independence

A module may depend on `core` and nothing else. If two modules need to share something, it belongs
in `core` or in neither. `tests/modules/test_module_independence.gd` fails on anything else. The
one allowed exception is listed at the top of that file, and adding to it means the module can no
longer be copied out on its own, so it needs a reason.

Modules do not assume what a project means by damage, currency, or interacting. They move a
`Variant` payload and let the receiver decide.

## Tests

New behaviour needs a test in `tests/modules/`. Open `tests/test_runner/test_runner.tscn` and
press F6, or run:

```
godot --headless --path . --script res://tests/terminal/run_all.gd
```

The suite must be green before a change lands. The seed is random each run and printed in the
report. Pass it back with `--seed=` to reproduce a failure. Some tests exercise failure paths, so
a passing run still prints four warnings.

## Commits

`area: Past-tense description`, one line. The area is the module name, or `docs`, `ci`, `tests`,
`global`.

```
socket: Fixed the marker transform on reparent
docs: Reworded the class summaries
```

## Retired code

Classes kept only so older scenes keep loading are marked `## @deprecated` and left out of the
documentation. `character/components/trash/` holds the current ones.
