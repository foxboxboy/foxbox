Zoom Spring Arm
===============

An extended SpringArm3D component for camera controllers. It replaces standard length adjustments with smooth, frame-independent zoom interpolation, clamp limits, precise signal emissions for UI/visibility toggling, and built-in multiplayer authority checks.

A ``SpringArm3D`` that interpolates its length instead of setting it directly. The interpolation
is frame independent.

It emits signals when the arm crosses configured thresholds, and skips processing when the node
does not have multiplayer authority.

.. toctree::
   :maxdepth: 1

   class_foxzoomspringarm3d
