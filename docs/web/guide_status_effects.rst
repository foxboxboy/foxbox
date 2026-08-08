Building a status effect system
===============================

In this guide you will build an enemy that can be hit by a sword, take damage, and catch fire.
The fire stacks up to three times, ticks damage every second, and sets a flag that particles can
watch.

It uses four modules together: :doc:`module_core` for the health pool,
:doc:`module_attribute_map` to store it, :doc:`module_damage` to deliver the hit, and
:doc:`module_effect` for the fire.

Prerequisites
-------------

FoxFabric installed and enabled, as described in :doc:`getting_started`.

Setting up the scenes
---------------------

Create two scenes.

.. code-block:: text

    Enemy            (CharacterBody3D, enemy.gd)
    ├─ Stats         (FoxAttributeMap)
    ├─ Effects       (FoxEffectManager)
    └─ HurtArea      (FoxHurtArea3D)

    Sword            (Node3D, sword.gd)
    └─ HitArea       (FoxHitArea3D)

Give the hurt area and the hit area a ``CollisionShape3D`` each.

Coding the enemy
----------------

Put the health pool in the attribute map rather than in a variable on the enemy. Effects and UI
can then reach it without holding a reference to the enemy script.

.. code-block:: gdscript

    class_name Enemy
    extends CharacterBody3D

    @onready var stats: FoxAttributeMap = $Stats
    @onready var effects: FoxEffectManager = $Effects

    func _ready() -> void:
        var health: FoxStatPool = FoxStatPool.new()
        health.base_max = 100.0
        stats.set_data(&"health", health)
        $HurtArea.hit_received.connect(_on_hit_received)

    func damage(amount: float) -> void:
        var health: FoxStatPool = stats.get_data(&"health") as FoxStatPool
        health.subtract(amount)
        if health.current <= 0.0:
            queue_free()

    func _on_hit_received(payload: Variant) -> void:
        var hit: Dictionary = payload as Dictionary
        if not hit:
            return
        damage(float(hit.get("amount", 0.0)))
        var effect: FoxEffect = hit.get("effect") as FoxEffect
        if effect:
            effects.add_effect(effect, self)

The enemy reads an amount and forwards any effect it was given. It does not know what fire is.

Creating the burn effect
------------------------

.. code-block:: gdscript

    class_name BurnEffect
    extends FoxEffect

    @export var damage_per_tick: float = 4.0

    func _on_execute(target: Object) -> void:
        var enemy: Enemy = target as Enemy
        if enemy:
            enemy.stats.increment_flag(&"burning")

    func _on_tick(target: Object, current_stack: int) -> void:
        var enemy: Enemy = target as Enemy
        if enemy:
            enemy.damage(damage_per_tick * current_stack)

    func _on_reapply(_target: Object, _current_stack: int = 1) -> void:
        pass

    func _on_remove(target: Object) -> void:
        var enemy: Enemy = target as Enemy
        if enemy:
            enemy.stats.decrement_flag(&"burning")

Save it as a resource and set ``stack_mode`` to ``INTENSITY``, ``max_stacks`` to ``3``,
``duration`` to ``6.0`` and ``tick_interval`` to ``1.0``.

``_on_tick`` multiplies by ``current_stack``, so three applications deal three times the damage
per tick. The flag is counted, so a second burn landing before the first expires keeps
``burning`` set until both are gone.

Coding the sword
----------------

.. code-block:: gdscript

    extends Node3D

    @export var burn: BurnEffect

    func _ready() -> void:
        $HitArea.payload = {"amount": 12.0, "effect": burn}

    func swing() -> void:
        $HitArea.fire()

Leave ``burn`` empty and the sword deals damage without applying anything. Assign a different
effect resource and it applies that instead. Neither script changes.

Reacting to the flag
--------------------

.. code-block:: gdscript

    stats.flag_added.connect(func(flag: StringName) -> void:
        if flag == &"burning":
            $BurnParticles.emitting = true)

    stats.flag_removed.connect(func(flag: StringName) -> void:
        if flag == &"burning":
            $BurnParticles.emitting = false)

``flag_added`` fires on the first stack and ``flag_removed`` on the last, so the particles start
and stop once no matter how many burns are applied.
