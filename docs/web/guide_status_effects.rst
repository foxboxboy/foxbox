Building a status effect system
===============================

Four modules combined into one feature: an enemy with health that can be hit, take damage, and
be set on fire.

* :doc:`module_core` for the health pool
* :doc:`module_attribute_map` for storing it and tracking a burning flag
* :doc:`module_damage` for delivering hits
* :doc:`module_effect` for the burn itself

Scene layout
------------

.. code-block:: text

    Enemy            (CharacterBody3D, enemy.gd)
    ├─ Stats         (FoxAttributeMap)
    ├─ Effects       (FoxEffectManager)
    └─ HurtArea      (FoxHurtArea3D)

    Sword            (Node3D, sword.gd)
    └─ HitArea       (FoxHitArea3D)

The enemy
---------

The health pool lives in the attribute map rather than as a variable on the enemy, so effects
and UI can reach it without holding a reference to the enemy script.

.. code-block:: gdscript

    class_name Enemy
    extends CharacterBody3D

    @onready var stats: FoxAttributeMap = $Stats
    @onready var effects: FoxEffectManager = $Effects

    func _ready() -> void:
        var health := FoxStatPool.new()
        health.base_max = 100.0
        stats.set_data(&"health", health)
        $HurtArea.hit_received.connect(_on_hit_received)

    func damage(amount: float) -> void:
        var health := stats.get_data(&"health") as FoxStatPool
        health.subtract(amount)
        if health.current <= 0.0:
            queue_free()

    func _on_hit_received(payload: Variant) -> void:
        var hit := payload as Dictionary
        if not hit:
            return
        damage(float(hit.get("amount", 0.0)))
        var effect := hit.get("effect") as FoxEffect
        if effect:
            effects.add_effect(effect, self)

The enemy does not know what burning is. It reads an amount and forwards any effect it was
handed.

The effect
----------

.. code-block:: gdscript

    class_name BurnEffect
    extends FoxEffect

    @export var damage_per_tick: float = 4.0

    func _on_execute(target: Object) -> void:
        var enemy := target as Enemy
        if enemy:
            enemy.stats.increment_flag(&"burning")

    func _on_tick(target: Object, current_stack: int) -> void:
        var enemy := target as Enemy
        if enemy:
            enemy.damage(damage_per_tick * current_stack)

    func _on_reapply(_target: Object, _current_stack: int = 1) -> void:
        pass

    func _on_remove(target: Object) -> void:
        var enemy := target as Enemy
        if enemy:
            enemy.stats.decrement_flag(&"burning")

Save it as a resource and set ``stack_mode`` to ``INTENSITY``, ``max_stacks`` to ``3``,
``duration`` to ``6.0`` and ``tick_interval`` to ``1.0``.

Because ``_on_tick`` multiplies by ``current_stack``, three applications deal three times the
damage per tick without any extra bookkeeping. Because the flag is counted, a second burn
landing before the first expires keeps ``burning`` set until both are gone.

The weapon
----------

.. code-block:: gdscript

    extends Node3D

    @export var burn: BurnEffect

    func _ready() -> void:
        $HitArea.payload = {"amount": 12.0, "effect": burn}

    func swing() -> void:
        $HitArea.fire()

Leave ``burn`` empty and the same sword deals damage without applying anything. Assign a
different effect resource and it applies that instead. Neither the sword nor the enemy changes.

Reacting to the flag
--------------------

Anything can watch the flag without knowing what set it.

.. code-block:: gdscript

    stats.flag_added.connect(func(flag: StringName) -> void:
        if flag == &"burning":
            $BurnParticles.emitting = true)

    stats.flag_removed.connect(func(flag: StringName) -> void:
        if flag == &"burning":
            $BurnParticles.emitting = false)

What each module contributed
----------------------------

The health pool clamps itself and reports overkill, so ``damage`` never needs to check bounds.
The attribute map holds the pool and the flag, so effects and UI reach them without a reference
to the enemy. The damage module moved a dictionary from the sword to the enemy without knowing
what was in it. The effect module handled duration, stacking and ticking.

The parts that are specific to this game are the two scripts above and the numbers on the
resource.
