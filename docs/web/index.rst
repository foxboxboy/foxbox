FoxFabric
=========

A lightweight, general purpose library for Godot 4.

It provides systems most projects end up writing themselves: entity stats, status effects, state
machines, hit detection, interaction, sockets, shops and cameras. Each module is a self contained
folder, so you can copy the whole ``addons/foxfabric`` directory or take a single one.

Most modules pass an arbitrary ``Variant`` payload between nodes rather than defining what your
project means by damage, currency or interacting. See :doc:`getting_started` for what that means
in practice.

These pages are generated from the ``##`` comments in the source, so they match the in-editor
help exactly.

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
