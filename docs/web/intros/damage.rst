Carries a ``Variant`` payload from one point in the world to another. Nothing in this module
reads the payload, so it contains no concept of health, teams or damage types.

Classes
-------

:ref:`class_FoxHitArea3D` delivers on overlap, or to everything currently inside it when
``fire()`` is called. Use it for melee arcs and explosions.

:ref:`class_FoxHitRayCast3D` delivers to the first hurtbox it strikes. Use it for hitscan.

:ref:`class_FoxHitShapeCast3D` sweeps a shape along a path. Use it for thick beams or fast melee
that would otherwise pass through a thin area.

:ref:`class_FoxHurtArea3D` receives a payload and re-emits it as ``hit_received``. It has an
``is_active`` property for invulnerability frames.

Usage
-----

.. code-block:: gdscript

    # attacker
    $HitArea.payload = {"amount": 12, "source": self, "type": &"slash"}

.. code-block:: gdscript

    # defender
    func _on_hit_received(payload: Variant) -> void:
        health -= payload["amount"]

Adding knockback, status effects or damage types means changing the payload, not this module.

Notes
-----

``receive_hit`` returns whether the payload was accepted. When ``is_active`` is ``false`` it
returns ``false`` and the deliverer does not emit ``hit_delivered``, so hit confirmation will not
fire against a target that ignored the hit.

.. note::

    Hurtboxes are areas, not bodies. Enable **collide with areas** on
    :ref:`class_FoxHitRayCast3D` and :ref:`class_FoxHitShapeCast3D` or they will never detect
    one.
