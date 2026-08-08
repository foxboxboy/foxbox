The "press E to open" pipeline, with no opinion about what interacting does.

A :ref:`class_FoxInteractionRayCast3D` points out of the player or camera and tracks whatever
interactable it is currently looking at, emitting focus and unfocus as the target changes. That
is what you connect a prompt or an outline shader to.

A :ref:`class_FoxInteractableArea3D` is the thing being looked at. When triggered it emits
``interacted`` with an arbitrary context, usually the initiator, so the object can decide what to
do with who did it.

.. code-block:: gdscript

    # on the player
    func _unhandled_input(event: InputEvent) -> void:
        if event.is_action_pressed(&"interact"):
            var target := $InteractionRay.get_current_target()
            if target:
                target.interact(self)

    # on the door
    func _on_interacted(context: Variant) -> void:
        if context.has_key(required_key):
            open()

The door decides it needs a key. The player does not know doors exist. Neither does this module.

How this differs from damage
----------------------------

The two modules look similar and are easy to confuse, so: :doc:`module_damage` is a **push**.
The attacker decides when something happens and sends a payload outward.

Interaction is a **pull**. The sensor continuously reports what is in front of you, and nothing
happens until something calls ``interact``. That is why interactables carry signals for focus
and unfocus, and hurtboxes do not.
