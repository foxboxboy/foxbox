Interaction
===========

A raycast-driven focus and activation pipeline. An interaction raycast focuses and triggers interactable volumes, which emit an arbitrary Variant context so the initiator decides what interacting actually means. The 2d and 3d folders hold the same pipeline for each dimension.

:ref:`class_FoxInteractionRayCast3D` tracks the :ref:`class_FoxInteractableArea3D` it currently
points at, emitting focus and unfocus as that changes. Calling ``interact`` on the area emits
``interacted`` with an arbitrary context.

.. code-block:: gdscript

    var target: FoxInteractableArea3D = $InteractionRay.get_current_target()
    if target:
        target.interact(self)

Calling ``interact`` does nothing by itself. It emits ``interacted`` and hands over whatever
context you passed in, and the code connected to that signal decides what interacting means:
picking the thing up, opening it, talking to it.

The ``2d`` folder holds the same pair, :ref:`class_FoxInteractionRayCast2D` and
:ref:`class_FoxInteractableArea2D`. One difference is worth knowing: ``interaction_range``
casts along local **+X** in 2D and local **-Z** in 3D, because that is the direction each
dimension treats as forward. ``Node2D.look_at`` orients +X at its target; ``Node3D.look_at``
orients -Z.

.. toctree::
   :maxdepth: 1

   module_interaction-2d
   module_interaction-3d
