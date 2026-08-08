Moves a ``RigidBody3D`` by applying forces and torques toward a target transform, rather than
setting its position directly. The body keeps colliding, keeps its mass, and can still get caught
on geometry.

.. code-block:: gdscript

    var hit_point := ray.get_collision_point()
    $Dragger.grab(body, hit_point, drag_profile)

``grab`` takes the contact point, so an object picked up by its edge pivots around that edge
instead of snapping to its centre.

Tuning lives in :ref:`class_FoxPhysicsDragProfile` resources rather than on the node, so one
dragger can handle a heavy crate and a light bottle with different settings swapped at runtime.
``stiffness`` controls how hard the body is pulled, ``damping`` how much it oscillates, and
``max_pull_force`` caps the force applied in a single frame.

See ``demos/interaction`` for a working setup.
