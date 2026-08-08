FoxFabric
=========

A lightweight, general purpose library for Godot 4.

A collection of the systems most projects end up rebuilding: entity stats, status effects, state
machines, hit detection, interaction, sockets, shops and cameras. Every module stands on its own,
so you can copy the whole ``addons/foxfabric`` folder or pull out the single directory you need.

Most of them move an arbitrary ``Variant`` payload around rather than hardcoding what your
project means by damage, currency or interacting. A module never has to know anything about the
game or tool it ends up in.

Every page here is generated from the ``##`` documentation comments in the source, so this site
and the in-editor help can never disagree.

.. toctree::
   :maxdepth: 1
   :caption: About

   getting_started

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
   module_deprecated
