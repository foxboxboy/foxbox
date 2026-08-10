Carrying physics objects
========================

In this guide you will build a player who can look at a crate, pick it up, carry it around, and
drop it. The crate stays a physics body the whole time, so it bumps into walls on the way.

It uses one module, :doc:`module_physics_dragging`. A runnable version is in
``demos/guides/carrying_physics_objects``, with mouse look added so there is something to aim at.

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

Only the last four matter to this module. The rest is somewhere to stand: a floor to drop things
on, a light to see them by, and two bodies to pick up.

``Player`` can be whatever you already use. Nothing here needs a physics body.

Point ``Aim`` down its local ``-Z`` and set its length to however far you want to reach. Move
``Dragger`` forward from the camera; whatever it grabs is pulled towards wherever the dragger is,
so its position is where the crate ends up floating.

The crate is a plain ``RigidBody3D`` with a collision shape. Nothing on it needs a script, but
give it a believable ``mass``. The dragger's defaults suit something substantial, and a body left
at the default 1 kg spins hard enough on grab to reach the physics engine's own limit and stay
there. Fifteen or twenty is fine for a crate.

Size the collision shape rather than scaling the body. Godot does not support scale on a physics
body, and a scaled one tumbles for reasons that look like a bug in the dragger.

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

One click does both, because ``is_holding`` says which case you are in. ``release`` dampens the
body's spin by default, so a crate you let go of does not keep rotating.

Where you grab matters
----------------------

The point handed to ``grab`` is where the ray actually struck the body, and the body pivots
around that point rather than its centre. Grab a plank by one end and it swings like a plank.

Passing the body's centre instead makes everything behave like a ball on a string, which is
worth knowing if that is what you wanted.

Changing the feel
-----------------

The dragger's own ``default_stiffness`` and ``default_damping`` cover most of it. For a heavy
crate that lags behind, hand ``grab`` a ``FoxPhysicsDragProfile`` instead.

.. code-block:: gdscript

    @export var heavy: FoxPhysicsDragProfile

    dragger.grab(body, aim.get_collision_point(), heavy)

Stiffness pulls harder, damping settles the wobble, and ``keep_upright`` stops the body tumbling
while carried. ``max_pull_force`` on the dragger caps all of it, so a stiff profile cannot launch
something across the level.
