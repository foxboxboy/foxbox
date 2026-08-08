Moves a ``RigidBody3D`` by applying forces and torques toward a target transform, rather than
setting its position directly. The body keeps colliding, keeps its mass, and can still get
caught on geometry.

Usage
-----

.. code-block:: gdscript

    var hit_point := ray.get_collision_point()
    $Dragger.grab(body, hit_point, drag_profile)

``grab`` takes the contact point, so an object picked up by its edge pivots around that edge
instead of snapping to its centre.

Profiles
--------

Tuning lives in :ref:`class_FoxPhysicsDragProfile` resources rather than on the node, so a heavy
crate and a light bottle can share one dragger with different settings, swapped at runtime.

``stiffness`` controls how hard the body is pulled, ``damping`` controls how much it oscillates,
and ``max_pull_force`` caps the force applied in a single frame.

See ``demos/interaction`` for a working setup, including rotating a held object.
