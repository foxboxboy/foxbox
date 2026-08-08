Carries a ``Variant`` payload between nodes. Nothing here reads the payload, so the module
contains no concept of health, teams or damage types.

:ref:`class_FoxHitArea3D` delivers on overlap, or to everything inside it when ``fire()`` is
called. :ref:`class_FoxHitRayCast3D` delivers to the first hurtbox it strikes.
:ref:`class_FoxHitShapeCast3D` sweeps a shape along a path. :ref:`class_FoxHurtArea3D` receives a
payload and re-emits it as ``hit_received``.

.. code-block:: gdscript

    $HitArea.payload = {"amount": 12, "source": self}

    func _on_hit_received(payload: Variant) -> void:
        health -= payload["amount"]

``receive_hit`` returns whether the payload was accepted. When ``is_active`` is ``false`` it
returns ``false`` and the deliverer does not emit ``hit_delivered``.

.. note::

    Hurtboxes are areas, not bodies. Enable **collide with areas** on
    :ref:`class_FoxHitRayCast3D` and :ref:`class_FoxHitShapeCast3D`.
