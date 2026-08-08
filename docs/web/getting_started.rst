Getting Started
===============

Installing
----------

Copy the ``addons/foxfabric`` folder into your project's ``addons`` folder, then enable
**FoxFabric** under ``Project > Project Settings > Plugins``.

Requires Godot 4.7 or newer. The demo scenes assume the Jolt physics engine, but the library
itself does not care which one you use.

There is nothing to configure and no autoload to register. Enabling the plugin only registers
the editor icons.

Taking only what you need
-------------------------

Every module is a self contained folder. Nothing outside ``core`` is required, and no module
reaches into another except through ``core``. If you only want the shop, copy
``addons/foxfabric/core`` and ``addons/foxfabric/shop`` and delete the rest.

That is also why there is no ``FoxFabric.something`` global. There is no manager to initialise
and no singleton holding state.

The idea behind it
------------------

Most of these modules move a ``Variant`` payload from one place to another and refuse to say
what it means.

A hitbox does not know what damage is. It carries whatever you put in it and hands it to a
hurtbox, which emits it as a signal. Deciding that ``payload["amount"]`` should be subtracted
from health is your job, in your code.

.. code-block:: gdscript

    # Attacker: describe the hit however your game wants
    $HitArea.payload = {"amount": 12, "source": self, "type": &"slash"}

    # Defender: a FoxHurtArea3D re-emits it, and you decide what it means
    func _on_hit_received(payload: Variant) -> void:
        health -= payload["amount"]
        if payload["type"] == &"slash":
            play_bleed_effect()

The same rule holds elsewhere. A :ref:`class_FoxPrice` decides what a currency is, so it can be
an integer, a list of scrap parts, or a reputation check. A :ref:`class_FoxInteractableArea3D`
emits an arbitrary context rather than assuming that interacting means opening a door.

This costs you some type safety. It buys a module that does not need editing when your game
turns out to work differently than the library author guessed.

Your first five minutes
-----------------------

Open ``demos/`` and run a scene. There is one per module and they are the fastest way to see
what something does. ``demos/damage`` and ``demos/interaction`` are the most illustrative.

After that, a reasonable order to read things in:

* :doc:`module_core` for the base classes and the stat maths
* :doc:`module_attribute_map` if you need entity stats or stacked status flags
* :doc:`module_state_machine` for splitting entity logic into states
* :doc:`module_damage` and :doc:`module_interaction` for the payload pipelines

Running the tests
-----------------

The library ships with its own test suite, which is a reasonable way to confirm nothing broke
after you have modified something.

Open ``tests/test_runner/test_runner.tscn`` and press :kbd:`F6`. Results appear on screen and
in the Output panel. From a terminal::

    godot --headless --path . --script res://tests/terminal/run_all.gd

A note on the character module
------------------------------

:doc:`module_character` is mid rewrite and does not reflect how the rest of the library is
written. Parts of it still hardcode things they should not. Read any other module for the
intended style.
