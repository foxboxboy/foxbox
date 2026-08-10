Carrying physics objects
========================

In this guide you will build a player who can look at a crate, pick it up, carry it around, and
drop it. The crate stays a physics body throughout, so it collides with the world on the way.

It uses one module, :doc:`module_physics_dragging`. A runnable version is in
``demos/guides/carrying_physics_objects``.

The 2D classes work the same way. Swap ``FoxPhysicsDragger3D`` for ``FoxPhysicsDragger2D`` and
``RigidBody3D`` for ``RigidBody2D``.

Prerequisites
-------------

FoxFabric installed and enabled, as described in :doc:`getting_started`.

Setting up the scene
--------------------

.. code-block:: text

    CarryingPhysicsObjects      (Node3D)
    ├─ WorldEnvironment
    ├─ DirectionalLight3D
    ├─ Ground                   (StaticBody3D)
    │  ├─ CollisionShape3D      (WorldBoundaryShape3D)
    │  └─ MeshInstance3D        (PlaneMesh)
    ├─ Crate                    (RigidBody3D, mass 15)
    │  ├─ CollisionShape3D      (BoxShape3D)
    │  └─ MeshInstance3D        (BoxMesh)
    ├─ Plank                    (RigidBody3D, mass 20)
    │  ├─ CollisionShape3D      (BoxShape3D, 2.5 x 0.2 x 0.6)
    │  └─ MeshInstance3D        (BoxMesh, same size)
    ├─ Player                   (Node3D, player.gd)
    │  └─ Camera3D
    │     ├─ Aim                (RayCast3D)
    │     └─ Dragger            (FoxPhysicsDragger3D)
    └─ Label

Only the last four belong to this module.

Point ``Aim`` down its local ``-Z`` and set its length to your reach. Move ``Dragger`` forward
from the camera. A grabbed body is pulled to the dragger, so that is where it floats.

Give each body a ``mass`` of fifteen or twenty. At Godot's default of 1 kg it spins up to the
physics engine's limit on grab and stays there.

Size the collision shape. Godot does not support scale on a physics body.

Grabbing and releasing
----------------------

.. code-block:: gdscript

    extends Node3D

    @onready var aim: RayCast3D = $Camera3D/Aim
    @onready var dragger: FoxPhysicsDragger3D = $Camera3D/Dragger

    func _unhandled_input(event: InputEvent) -> void:
        var button: InputEventMouseButton = event as InputEventMouseButton
        if button == null or not button.pressed:
            return
        if button.button_index != MOUSE_BUTTON_LEFT:
            return

        if dragger.is_holding():
            dragger.release()
            return

        var body: RigidBody3D = aim.get_collider() as RigidBody3D
        if body != null:
            dragger.grab(body, aim.get_collision_point())

``release`` dampens the body's spin unless you pass ``false``.

Where you grab matters
----------------------

The point handed to ``grab`` is where the ray struck the body, and the body pivots around that
point rather than its centre. Grab a plank by one end and it swings like a plank.

Passing the body's centre instead makes it behave like a ball on a string.

Changing the feel
-----------------

``default_stiffness`` and ``default_damping`` on the dragger cover most cases. For a heavy crate
that lags behind, hand ``grab`` a ``FoxPhysicsDragProfile``.

.. code-block:: gdscript

    @export var heavy: FoxPhysicsDragProfile

    dragger.grab(body, aim.get_collision_point(), heavy)

Stiffness pulls harder, damping settles the wobble, ``keep_upright`` stops the body tumbling
while carried. ``max_pull_force`` on the dragger caps all three.
