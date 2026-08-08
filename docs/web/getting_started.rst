Getting Started
===============

Installing
----------

Copy ``addons/foxfabric`` into your project's ``addons`` folder, then enable **FoxFabric** under
``Project > Project Settings > Plugins``.

Requires Godot 4.7 or newer. The demo scenes use the Jolt physics engine. The library does not
depend on it.

There is nothing to configure and no autoload to register. Enabling the plugin only registers
the editor icons.

Using part of the library
-------------------------

Each module is a self contained folder. Only ``core`` is required, and no module depends on
another except through ``core``. To use just the shop, copy ``addons/foxfabric/core`` and
``addons/foxfabric/shop`` and delete the rest.

There is no global singleton and no manager to initialise.

Payloads
--------

Most modules pass a ``Variant`` payload between nodes without reading it. A hitbox carries
whatever you assign and hands it to a hurtbox, which emits it as a signal. Interpreting it is
done by your code.

.. code-block:: gdscript

    # attacker
    $HitArea.payload = {"amount": 12, "source": self, "type": &"slash"}

.. code-block:: gdscript

    # defender
    func _on_hit_received(payload: Variant) -> void:
        health -= payload["amount"]
        if payload["type"] == &"slash":
            play_bleed_effect()

The same applies elsewhere. A :ref:`class_FoxPrice` defines what a currency is, so it can be an
integer, a list of items, or a level requirement. A :ref:`class_FoxInteractableArea3D` emits an
arbitrary context instead of assuming what interacting means.

This trades compile time type safety for modules that do not need editing when your project
works differently than expected.

Where to start
--------------

Run a scene from ``demos/``. There is one per module. ``demos/damage`` and
``demos/interaction`` show the payload pattern most clearly.

Then read, in order:

* :doc:`module_core` for the base classes and stat maths
* :doc:`module_attribute_map` for entity stats and stacked flags
* :doc:`module_state_machine` for splitting entity logic into states
* :doc:`module_damage` and :doc:`module_interaction` for the payload pipelines

Running the tests
-----------------

Open ``tests/test_runner/test_runner.tscn`` and press :kbd:`F6`. Results appear on screen and in
the Output panel.

From a terminal::

    godot --headless --path . --script res://tests/terminal/run_all.gd

It exits ``0`` on success and ``1`` on failure. Some tests deliberately exercise failure paths,
so warnings appear during a passing run.

.. warning::

    :doc:`module_character` is mid rewrite and does not follow the conventions used elsewhere in
    the library. Read another module for the intended style.
