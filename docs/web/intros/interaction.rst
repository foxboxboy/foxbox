Detects what the player is looking at and triggers it. What triggering does is defined by the
object, not by this module.

:ref:`class_FoxInteractionRayCast3D` points out of the player or camera and tracks the
interactable in front of it, emitting focus and unfocus as the target changes. Connect those to a
prompt or an outline shader. :ref:`class_FoxInteractableArea3D` is the target, and calling
``interact`` emits ``interacted`` with an arbitrary context, usually the initiator.

.. code-block:: gdscript

    # player.gd
    func _unhandled_input(event: InputEvent) -> void:
        if event.is_action_pressed(&"interact"):
            var target := $InteractionRay.get_current_target()
            if target:
                target.interact(self)

.. code-block:: gdscript

    # door.gd
    func _on_interacted(context: Variant) -> void:
        if context.has_key(required_key):
            open()

:doc:`module_damage` pushes, in that the attacker decides when a payload is sent. Interaction
pulls: the sensor reports what is in front of it continuously and nothing happens until
``interact`` is called. That is why interactables have focus and unfocus signals and hurtboxes do
not.
