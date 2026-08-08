Timed modifiers applied to a target: buffs, debuffs and damage over time.

A :ref:`class_FoxEffect` is a ``Resource`` holding the static definition, such as duration, tick
rate and stacking rules. A :ref:`class_FoxEffectInstance` is created per application and holds
the mutable state, such as remaining time and stack count. Instances are not nodes, so ten
poisoned enemies means one resource and ten lightweight instances.

A :ref:`class_FoxEffectManager` on the entity owns the instances. It only processes while at
least one effect is active.

Writing an effect
-----------------

Extend :ref:`class_FoxEffect` and implement all four methods. They are abstract, so an empty
body is still required.

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

Set ``stack_mode`` to ``INTENSITY`` and ``tick_interval`` to ``1.0`` on the resource to make the
effect above stack and tick once per second.

Notes
-----

.. note::

    ``max_stacks`` of ``0`` means unlimited. To prevent stacking entirely, use
    ``StackMode.UNIQUE``.

.. note::

    ``duration`` of ``-1.0`` means permanent. Any other negative value expires immediately.

``_on_reapply`` runs on every stack change, including decreases, so it should recalculate from
the stack count it receives rather than adding to the previous result.

``_on_remove`` is skipped when a save file is loaded, so it should not be the only place that
cleans up state. The manager can serialise and restore active effects without replaying their
initial application.
