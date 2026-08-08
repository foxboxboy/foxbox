FoxFabric
=========

A lightweight, general purpose library for Godot 4.

It provides the systems most projects end up writing themselves: entity stats, status effects,
state machines, hit detection, interaction, sockets, shops and cameras. Each module is a self
contained folder with no shared state and no autoload, so you can take one and leave the rest.

.. note::

    FoxFabric is version 0.1 and is a personal library first. Expect the API to change between
    versions. The ``character`` module in particular is being rewritten.

Where to start
--------------

.. raw:: html

    <div class="ff-tiles">
      <a class="ff-tile ff-tile-start" href="getting_started.html">
        <strong>New to FoxFabric</strong>
        <span>Install it, and understand how the modules talk to each other.</span>
      </a>
      <a class="ff-tile ff-tile-build" href="guide_status_effects.html">
        <strong>Show me it working</strong>
        <span>Build an enemy with health, damage and a stacking burn effect.</span>
      </a>
      <a class="ff-tile ff-tile-api" href="module_core.html">
        <strong>I know what I need</strong>
        <span>Browse the class reference, grouped by module.</span>
      </a>
      <a class="ff-tile ff-tile-repo" href="https://github.com/tateorrtot/foxfabric-godot">
        <strong>Source and issues</strong>
        <span>The repository, including the demo scenes and the test suite.</span>
      </a>
    </div>

What makes it different
-----------------------

Most modules move an arbitrary ``Variant`` payload between nodes and never look inside it. A
hitbox carries whatever you assign and hands it to a hurtbox, which emits it as a signal.
Deciding that it means damage is your code's job.

.. code-block:: gdscript

    $HitArea.payload = {"amount": 12, "source": self}

    func _on_hit_received(payload: Variant) -> void:
        health -= payload["amount"]

The same applies to currency, interaction and entity data. That trades compile time type safety
for modules that need no editing when a project uses them in a way the author did not predict.

What is in it
-------------

**Data and logic**, with no spatial dependency: :doc:`module_core` for base classes and stat
maths, :doc:`module_attribute_map` for entity data and stacked flags, :doc:`module_effect` for
buffs and debuffs, :doc:`module_state_machine`, and :doc:`module_shop`.

**Spatial**, 3D unless noted: :doc:`module_socket` (2D and 3D), :doc:`module_damage`,
:doc:`module_interaction`, :doc:`module_aim_gimbal`, :doc:`module_zoom_spring_arm`,
:doc:`module_physics_dragging`, :doc:`module_view_model` and :doc:`module_character`.

Every page in the class reference is generated from the ``##`` comments in the source, so this
site and the in-editor help cannot disagree.

.. toctree::
   :maxdepth: 1
   :caption: About

   getting_started

.. toctree::
   :maxdepth: 1
   :caption: Guides

   guide_status_effects

.. toctree::
   :maxdepth: 1
   :caption: Modules

   module_core
   module_attribute_map
   module_effect
   module_state_machine
   module_shop
   module_socket
   module_damage
   module_interaction
   module_aim_gimbal
   module_zoom_spring_arm
   module_physics_dragging
   module_view_model
   module_character
