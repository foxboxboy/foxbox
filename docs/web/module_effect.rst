Effect
======

A memory-safe Flyweight architecture for managing the lifecycle, stacking, and interval ticking of temporary gameplay modifiers (buffs and debuffs) without SceneTree bloat.

A :ref:`class_FoxEffect` is a ``Resource`` holding the definition: duration, tick rate and
stacking rules. A :ref:`class_FoxEffectInstance` is created per application and holds the mutable
state. Instances are not nodes. A :ref:`class_FoxEffectManager` owns them and only processes while
at least one is active.

Extend :ref:`class_FoxEffect` and implement all four methods. They are abstract, so an empty body
is still required.

.. code-block:: gdscript

    extends FoxEffect

    @export var damage_per_tick: float = 2.0

    func _on_execute(target: Object) -> void:
        pass

    func _on_tick(target: Object, current_stack: int) -> void:
        target.health -= damage_per_tick * current_stack

    func _on_reapply(target: Object, current_stack: int = 1) -> void:
        pass

    func _on_remove(target: Object) -> void:
        pass

``_on_reapply`` runs on every stack change including decreases, so recalculate from the stack
count it receives. ``_on_remove`` is skipped when a save file is loaded.

.. note::

    ``max_stacks`` of ``0`` means unlimited. Use ``StackMode.UNIQUE`` to prevent stacking.
    ``duration`` of ``-1.0`` means permanent.

.. toctree::
   :maxdepth: 1

   class_foxeffect
   class_foxeffectinstance
   class_foxeffectmanager
   class_foxeffectslotpolicy
