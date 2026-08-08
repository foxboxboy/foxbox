Getting Started
===============

Installing
----------

Copy ``addons/foxfabric`` into your project's ``addons`` folder and enable **FoxFabric** under
``Project > Project Settings > Plugins``.

Requires Godot 4.7 or newer. There is no autoload and nothing to configure. Enabling the plugin
registers the editor icons.

Each module is a self contained folder. Only ``core`` is required, and no module depends on
another except through ``core``, so you can copy a single module and ``core`` instead of the whole
addon.

Payloads
--------

Most modules pass a ``Variant`` between nodes without reading it. A hitbox carries whatever is
assigned to it and hands it to a hurtbox, which emits it as a signal.

.. code-block:: gdscript

    $HitArea.payload = {"amount": 12, "source": self}

    func _on_hit_received(payload: Variant) -> void:
        health -= payload["amount"]

The same applies to :ref:`class_FoxPrice`, which defines what a currency is, and
:ref:`class_FoxInteractableArea3D`, which emits an arbitrary context. This trades compile time
type safety for modules that need no editing when a project uses them differently.

Demos
-----

``demos/`` has one scene per module.

Tests
-----

Open ``tests/test_runner/test_runner.tscn`` and press :kbd:`F6`, or from a terminal::

    godot --headless --path . --script res://tests/terminal/run_all.gd

It exits ``0`` on success and ``1`` on failure. Some tests exercise failure paths, so warnings
appear during a passing run.
