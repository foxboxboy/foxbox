FoxFabric
=========

A lightweight, general purpose library for Godot 4.

Entity stats, status effects, state machines, hit detection, interaction, sockets, shops and
cameras. Each module is a self contained folder.

Most modules pass an arbitrary ``Variant`` between nodes rather than defining what a project means
by damage, currency or interacting.

These pages are generated from the ``##`` comments in the source and match the in-editor help.

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
