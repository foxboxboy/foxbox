Physics Dragging
================

Manipulates a RigidBody3D by applying localized forces and torques to pull it toward a target node. Stiffness, damping, and force limits live in swappable FoxPhysicsDragProfile resources.

Moves a ``RigidBody3D`` by applying forces and torques toward a target transform rather than
setting its position, so the body keeps colliding and keeps its mass.

.. code-block:: gdscript

    $Dragger.grab(body, ray.get_collision_point(), drag_profile)

``grab`` takes a contact point, so the body pivots around it rather than snapping to its centre.

Tuning lives in :ref:`class_FoxPhysicsDragProfile` resources, which can be swapped at runtime.
``stiffness`` controls the pull, ``damping`` the oscillation, and ``max_pull_force`` caps the
force applied per frame.

.. toctree::
   :maxdepth: 1

   class_foxphysicsdragger3d
   class_foxphysicsdragprofile
