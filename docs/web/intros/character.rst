.. warning::

    Under rewrite. This module does not follow the conventions used by the rest of the library
    and its API will change. Read another module for the intended style.

A humanoid controller for ``CharacterBody3D``: motors, abilities, movement states, a resizable
collision capsule, and the mannequin and accessory assets used by the demos.

Classes
-------

:ref:`class_FoxCharacterMotor3D` moves a body from an input direction.
:ref:`class_FoxAdvancedCharacterMotor3D` adds acceleration, friction and pushing
``RigidBody3D`` out of the way.

Abilities and movement states are separate nodes layered on top.
:ref:`class_FoxDynamicCapsule` resizes the collision shape for crouching.

Known problems
--------------

Configuration that should live in resources is hardcoded. ``crouch()`` and a crouch height sit
on the hitbox instead of in a swappable profile.

The module has no test coverage. Every other module does.

Treat it as a starting point to copy and modify rather than a stable dependency.
