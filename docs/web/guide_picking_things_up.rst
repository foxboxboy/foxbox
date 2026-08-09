Picking things up
=================

In this guide you will build a player who can look at a crate, see a prompt, and press a key to
pick it up. It uses one module, :doc:`module_interaction`, and two nodes from it.

The 2D classes work the same way. Swap ``FoxInteractionRayCast3D`` for ``FoxInteractionRayCast2D``
and ``FoxInteractableArea3D`` for ``FoxInteractableArea2D``.

Prerequisites
-------------

FoxFabric installed and enabled, as described in :doc:`getting_started`.

Setting up the scene
--------------------

Create two scenes.

.. code-block:: text

    Player           (CharacterBody3D, player.gd)
    └─ Camera3D
       └─ Sensor     (FoxInteractionRayCast3D)

    Crate            (Crate, crate.gd)
    └─ CollisionShape3D

``Crate`` extends ``FoxInteractableArea3D``, so the crate scene's root is the interactable
itself. Point the sensor's ``target_position`` down its local ``-Z``, and enable
``collide_with_areas`` on it or it will never see the crate.

Making the crate interactable
-----------------------------

Override ``_interact`` rather than connecting to the ``interacted`` signal. The signal is there
for anything else that wants to watch.

.. code-block:: gdscript

    class_name Crate
    extends FoxInteractableArea3D

    @export var contents: StringName = &"scrap"

    func _interact(context: Variant) -> void:
        var player: Player = context as Player
        if player == null:
            return

        player.collect(contents)
        queue_free()

The crate decides what happens to it. The player never reaches inside.

Interacting with it
-------------------

The sensor tracks whatever it is pointing at. ``interact_with_target`` passes a context of your
choosing straight through to ``_interact``, and does nothing when there is no target.

.. code-block:: gdscript

    class_name Player
    extends CharacterBody3D

    @onready var sensor: FoxInteractionRayCast3D = $Camera3D/Sensor

    var carried: Array[StringName] = []

    func _unhandled_input(event: InputEvent) -> void:
        if event.is_action_pressed(&"interact"):
            sensor.interact_with_target(self)

    func collect(item: StringName) -> void:
        carried.append(item)

Passing ``self`` is what lets the crate call back into the player. Pass a dictionary instead if
the crate needs more than the caller.

Showing a prompt
----------------

The sensor emits when the target changes, not every frame.

.. code-block:: gdscript

    func _ready() -> void:
        sensor.focused.connect(_on_focused)
        sensor.unfocused.connect(_on_unfocused)

    func _on_focused(_interactable: FoxInteractableArea3D) -> void:
        $HUD/Prompt.show()

    func _on_unfocused(_interactable: FoxInteractableArea3D) -> void:
        $HUD/Prompt.hide()

``FoxInteractableArea3D`` emits its own ``focused`` and ``unfocused`` alongside these, so a crate
can highlight itself without the player knowing it does.
