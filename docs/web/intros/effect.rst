Timed modifiers applied to a target: buffs, debuffs and damage over time.

A :ref:`class_FoxEffect` is a ``Resource`` holding the static definition, such as duration, tick
rate and stacking rules. A :ref:`class_FoxEffectInstance` is created per application and holds
the mutable state. Instances are not nodes, so ten poisoned enemies means one resource and ten
lightweight instances. A :ref:`class_FoxEffectManager` on the entity owns them and only processes
while at least one is active.

To write an effect, extend :ref:`class_FoxEffect` and implement all four methods. They are
abstract, so an empty body is still required.

.. code-block:: gdscript

    extends FoxEffect

    @export var damage_per_tick: float = 2.0

    func _on_execute(target: Object) -> void:
        target.play_poison_vfx()

    func _on_tick(target: Object, current_stack: int) -> void:
        target.health -= damage_per_tick * current_stack

    func _on_reapply(target: Object, current_stack: int = 1) -> void:
        pass

    func _on_remove(target: Object) -> void:
        target.stop_poison_vfx()

Set ``stack_mode`` to ``INTENSITY`` and ``tick_interval`` to ``1.0`` on the resource to make that
effect stack and tick once per second.

``_on_reapply`` runs on every stack change, including decreases, so it should recalculate from
the stack count it receives rather than adding to the previous result. ``_on_remove`` is skipped
when a save file is loaded, so it should not be the only place that cleans up state.

.. note::

    ``max_stacks`` of ``0`` means unlimited. To prevent stacking entirely use
    ``StackMode.UNIQUE``. ``duration`` of ``-1.0`` means permanent, and any other negative value
    expires immediately.
