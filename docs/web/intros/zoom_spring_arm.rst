A ``SpringArm3D`` that interpolates its length instead of setting it directly. The interpolation
is frame independent.

It emits signals when the arm crosses configured thresholds, and skips processing when the node
does not have multiplayer authority.
