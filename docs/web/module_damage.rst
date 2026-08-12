:github_url: hide

Damage
======

Hit areas, raycasts, and shapecasts that deliver a payload to hurt areas.

Carries a ``Variant`` payload between nodes. Nothing here reads the payload, so the module
contains no concept of health, teams or damage types.

:ref:`class_FoxHitArea3D` delivers on overlap, or to everything inside it when ``fire()`` is
called. :ref:`class_FoxHitRayCast3D` delivers to the first hurtbox it strikes.
:ref:`class_FoxHitShapeCast3D` sweeps a shape along a path. :ref:`class_FoxHurtArea3D` receives a
payload and re-emits it as ``hit_received``.

The ``2d`` folder holds the same four, built on ``Area2D``, ``RayCast2D`` and ``ShapeCast2D``:
:ref:`class_FoxHitArea2D`, :ref:`class_FoxHitRayCast2D`, :ref:`class_FoxHitShapeCast2D` and
:ref:`class_FoxHurtArea2D`. The routing and the acceptance contract are identical, and the two
dimensions never talk to each other.

.. code-block:: gdscript

    $HitArea.payload = {"amount": 12, "source": self}

    func _on_hit_received(payload: Variant) -> void:
        health -= payload["amount"]

``receive_hit`` returns whether the payload was accepted. When ``is_active`` is ``false`` it
returns ``false`` and the deliverer does not emit ``hit_delivered``.

.. note::

    Hurtboxes are areas, not bodies. Enable **collide with areas** on any of the casts,
    in either dimension. Each one warns in the inspector when you have not.

.. toctree::
   :maxdepth: 1

   module_damage-2d
   module_damage-3d
