:github_url: hide

Zoom Spring Arm
===============

A SpringArm3D that eases to a new length instead of snapping, between a minimum and maximum. Emits when it reaches either end, so UI can show or hide with the camera.

A ``SpringArm3D`` that interpolates its length instead of setting it directly. The interpolation
is frame independent.

It emits signals when the arm crosses configured thresholds, and skips processing when the node
does not have multiplayer authority.

.. toctree::
   :maxdepth: 1

   class_foxzoomspringarm3d
