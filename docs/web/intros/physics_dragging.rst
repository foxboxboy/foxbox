Picking up a ``RigidBody3D`` and carrying it without breaking the simulation.

The naive approach is to set the body's position every frame, which makes it pass through walls
and behave like a kinematic object wearing a rigid body costume.
:ref:`class_FoxPhysicsDragger3D` instead applies forces and torques to pull the body toward the
dragger's transform, so it still collides, still has weight, and still gets stuck on things.

That is the difference between a gravity gun that feels physical and one that feels like
cheating.

.. code-block:: gdscript

    var hit_point := ray.get_collision_point()
    $Dragger.grab(body, hit_point, drag_profile)

Grabbing takes the contact point, so an object picked up by its edge pivots around that edge
rather than snapping to its centre.

Tuning lives in :ref:`class_FoxPhysicsDragProfile` resources rather than on the node, which
means a heavy crate and a light bottle can use the same dragger with different feel, swapped at
runtime. Stiffness controls how hard it pulls, damping controls the wobble, and there is a hard
cap on force so a grabbed object can never launch across the level.

See ``demos/interaction`` for a working setup, including rotating a held object with the right
mouse button.
