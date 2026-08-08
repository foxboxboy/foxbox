A delivery pipeline that carries a ``Variant`` from one place in the world to another and never
looks inside it.

Despite the module name, nothing here mentions health, teams, resistances or damage types. It
moves a payload. That the payload usually describes damage is your decision, not the library's.

Deliverers and receivers
------------------------

Three ways to deliver, one way to receive.

:ref:`class_FoxHitArea3D`
    An ``Area3D`` that delivers on overlap, or instantly to everything inside it when you call
    ``fire()``. Use it for melee arcs and explosions.

:ref:`class_FoxHitRayCast3D`
    Hitscan. Delivers to the first hurtbox it strikes.

:ref:`class_FoxHitShapeCast3D`
    A swept shape, for thick lasers or fast melee that would otherwise tunnel through a thin
    area.

:ref:`class_FoxHurtArea3D`
    The receiving end. It re-emits whatever arrives as ``hit_received`` and has an ``is_active``
    toggle for invulnerability frames.

.. code-block:: gdscript

    # attacker
    $HitArea.payload = {"amount": 12, "source": self, "type": &"slash"}

    # defender
    func _on_hit_received(payload: Variant) -> void:
        health -= payload["amount"]

Because the payload is opaque, adding knockback, status effects or a damage type means changing
your dictionary, not this module.

An inactive hurtbox refuses
---------------------------

``receive_hit`` returns whether the payload was accepted. When ``is_active`` is off it returns
``false`` and the deliverer does not emit ``hit_delivered``, so your hit-confirmation feedback
will not fire on a target that ignored the hit. That matters for anything driving a hitmarker or
a combo counter.

Remember that the raycast and shapecast deliverers need **collide with areas** enabled in the
inspector, since hurtboxes are areas rather than bodies.
