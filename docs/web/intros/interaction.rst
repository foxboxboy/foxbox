:ref:`class_FoxInteractionRayCast3D` tracks the :ref:`class_FoxInteractableArea3D` it currently
points at, emitting focus and unfocus as that changes. Calling ``interact`` on the area emits
``interacted`` with an arbitrary context.

.. code-block:: gdscript

    var target := $InteractionRay.get_current_target()
    if target:
        target.interact(self)

The module defines no behaviour for interacting. The receiver does.

The ``2d`` folder holds the same pair, :ref:`class_FoxInteractionRayCast2D` and
:ref:`class_FoxInteractableArea2D`. One difference is worth knowing: ``interaction_range``
casts along local **+X** in 2D and local **-Z** in 3D, because that is the direction each
dimension treats as forward. ``Node2D.look_at`` orients +X at its target; ``Node3D.look_at``
orients -Z.
