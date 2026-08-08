Buffs, debuffs, damage over time, and anything else that applies to a target for a while and
then stops.

The split that makes this work is between the **blueprint** and the **instance**. A
:ref:`class_FoxEffect` is a ``Resource``, so "poison" exists once on disk with its duration,
tick rate and stacking rules. A :ref:`class_FoxEffectInstance` is created per application and
holds only the mutable state: how long is left, how many stacks. Ten poisoned enemies means one
resource and ten small instances, none of which are nodes.

A :ref:`class_FoxEffectManager` sits on the entity and owns the instances. It only processes
while something is active, so an entity with no effects costs nothing per frame.

Writing an effect
-----------------

Extend :ref:`class_FoxEffect` and implement all four hooks. They are abstract, so the engine
requires them even when the body is empty.

.. code-block:: gdscript

    extends FoxEffect

    @export var damage_per_tick: float = 2.0

    func _on_execute(target: Object) -> void:
        target.play_poison_vfx()

    func _on_tick(target: Object, current_stack: int) -> void:
        target.health -= damage_per_tick * current_stack

    func _on_reapply(target: Object, current_stack: int = 1) -> void:
        pass  # ticking already reads the stack, nothing to rescale

    func _on_remove(target: Object) -> void:
        target.stop_poison_vfx()

Then set ``stack_mode`` to ``INTENSITY`` and ``tick_interval`` to ``1.0`` on the resource, and
applying it twice gives you a two stack poison ticking once per second.

Things that will catch you out
------------------------------

``max_stacks`` of ``0`` means **unlimited**, not zero. If you want an effect that never stacks,
use ``StackMode.UNIQUE`` instead.

``duration`` of ``-1.0`` means **permanent**. Any other negative value expires immediately.

``_on_reapply`` should recalculate from the stack count it is given rather than adding to
whatever it applied last time, because it fires on every stack change including decreases.

``_on_remove`` is deliberately skipped when a save file is loaded, so it must not be the only
thing that cleans up state. The manager can serialise and restore active effects, and it
restores them without replaying their initial burst.
