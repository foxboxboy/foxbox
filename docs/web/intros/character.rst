.. warning::

   Under heavy rewrite. This module does not reflect how the rest of the library is written, and
   its API will change. Read any other module for the intended style.

A humanoid controller for ``CharacterBody3D``: motors, abilities, movement states, a dynamic
collision capsule, and the mannequin and accessory assets the demos use.

What is here
------------

:ref:`class_FoxCharacterMotor3D` moves a body from an input direction. The advanced version adds
acceleration, friction and pushing ``RigidBody3D`` out of the way, which is what gives it weight
rather than the on-off feel of the basic one.

Abilities and movement states are separate nodes layered on top, and
:ref:`class_FoxDynamicCapsule` resizes the collision shape for crouching.

Why it is being rewritten
-------------------------

The rest of the library keeps configuration in resources and refuses to assume what your game
does. This module does neither yet. Pieces of it hardcode behaviour that should be data, such as
a ``crouch()`` method and a crouch height living on the hitbox instead of in a swappable profile.

It also has no test coverage, while every other module does.

Use it as a starting point to copy and modify rather than as a stable dependency. If you want an
example of how a FoxFabric module is supposed to look, read :doc:`module_effect` or
:doc:`module_shop` instead.
