Interaction
===========

A raycast-driven focus and activation pipeline. FoxInteractionRayCast3D focuses and triggers FoxInteractableArea3D volumes, which emit an arbitrary Variant context so the initiator decides what interacting actually means.

:ref:`class_FoxInteractionRayCast3D` tracks the :ref:`class_FoxInteractableArea3D` it currently
points at, emitting focus and unfocus as that changes. Calling ``interact`` on the area emits
``interacted`` with an arbitrary context.

.. code-block:: gdscript

    var target := $InteractionRay.get_current_target()
    if target:
        target.interact(self)

The module defines no behaviour for interacting. The receiver does.

.. toctree::
   :maxdepth: 1

   class_foxinteractablearea3d
   class_foxinteractionraycast3d
