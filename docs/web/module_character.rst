:github_url: hide

Character
=========

Motors, abilities, and states for driving a CharacterBody3D, plus the mannequin and accessory assets the demos use. Under heavy refactor.

.. warning::

    Under rewrite. This module does not follow the conventions used by the rest of the library
    and its API will change.

A humanoid controller for ``CharacterBody3D``: motors, abilities, movement states, a resizable
collision capsule, and the mannequin and accessory assets used by the demos.

:ref:`class_FoxCharacterMotor3D` moves a body from an input direction, and
:ref:`class_FoxAdvancedCharacterMotor3D` adds acceleration, friction and pushing ``RigidBody3D``
out of the way. Abilities and movement states are separate nodes layered on top, and
:ref:`class_FoxDynamicCapsule` resizes the collision shape for crouching.

Configuration that belongs in resources is currently hardcoded, and the module has no test
coverage.

.. toctree::
   :maxdepth: 1

   module_character-components
   module_character-refactor
