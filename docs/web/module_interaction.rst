Interaction
===========

A raycast-driven focus and activation pipeline. An interaction raycast focuses and triggers interactable volumes, which emit an arbitrary Variant context so the initiator decides what interacting actually means. The 2d and 3d folders hold the same pipeline for each dimension.

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

   module_interaction-2d
   module_interaction-3d
