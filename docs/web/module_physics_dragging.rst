Physics Dragging
================

Pulls a RigidBody towards a target node with forces and torque, so it still collides with the world on the way. Stiffness and damping live in a resource you can swap.

Moves a ``RigidBody3D`` by applying forces and torques toward a target transform rather than
setting its position, so the body keeps colliding and keeps its mass.

.. code-block:: gdscript

    $Dragger.grab(body, ray.get_collision_point(), drag_profile)

``grab`` takes a contact point, so the body pivots around it rather than snapping to its centre.

Tuning lives in :ref:`class_FoxPhysicsDragProfile` resources, which can be swapped at runtime.
``stiffness`` controls the pull, ``damping`` the oscillation, and ``max_pull_force`` caps the
force applied per frame.

:ref:`class_FoxPhysicsDragger2D` does the same for a ``RigidBody2D``. The profile is shared
rather than duplicated, since stiffness and damping mean the same thing in both dimensions, so
it sits at the module root next to the ``2d`` and ``3d`` folders.

``keep_upright`` differs between them. In 3D the held body still turns to follow the dragger and
only the tipping is removed. In 2D there is no facing to preserve, so the body is simply held at
zero rotation.

.. toctree::
   :maxdepth: 1

   module_physics_dragging-2d
   module_physics_dragging-3d
   class_foxphysicsdragprofile
