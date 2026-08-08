A ``SpringArm3D`` that interpolates its length instead of setting it directly, so a third person
camera can move between over the shoulder and pulled back without snapping. The interpolation is
frame independent.

It emits signals when the arm crosses configured thresholds. Connect those to hide the player
model when the camera moves close enough to see inside it. Using signals rather than polling
means the toggle happens once per crossing.

A multiplayer authority check is built in, so an arm belonging to a peer you do not control will
not take over the camera.

.. note::

    Pair it with :doc:`module_aim_gimbal`. The gimbal controls where the camera looks, the arm
    controls how far away it sits.
