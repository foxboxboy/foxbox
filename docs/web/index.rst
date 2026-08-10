FoxFabric
=========

A lightweight, general purpose library for Godot 4. Entity stats, status effects, state
machines, hit detection, interaction, sockets, shops and cameras, as self contained modules with
no shared state and no autoload.

.. raw:: html

    <div class="ff-tiles">
      <a class="ff-tile ff-tile-start" href="getting_started.html">
        <strong>New to FoxFabric</strong>
        <span>Install it and see how the modules fit together.</span>
      </a>
      <a class="ff-tile ff-tile-build" href="guide_status_effects.html">
        <strong>Show me it working</strong>
        <span>Build an enemy with health, damage and a stacking burn.</span>
      </a>
      <a class="ff-tile ff-tile-api" href="module_core.html">
        <strong>I know what I need</strong>
        <span>The class reference, grouped by module.</span>
      </a>
      <a class="ff-tile ff-tile-repo" href="https://github.com/tateorrtot/foxfabric-godot">
        <strong>Source and issues</strong>
        <span>Repository, demo scenes and test suite.</span>
      </a>
    </div>

.. note::

    Version 0.1. Expect the API to change between versions, and the ``character`` module to
    change most.

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
