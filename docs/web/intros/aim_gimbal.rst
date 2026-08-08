A hinge that turns accumulated 2D input into safe pitch and yaw.

Mouse look is the obvious use, but the same node drives a turret, a security camera or anything
else that swivels on two axes.

.. code-block:: gdscript

    func _unhandled_input(event: InputEvent) -> void:
        if event is InputEventMouseMotion:
            $Gimbal.yaw -= event.relative.x * sensitivity
            $Gimbal.pitch -= event.relative.y * sensitivity

Each axis independently either clamps or wraps. Pitch clamps by default, because letting a
first person camera roll over the top is almost never what you want. Yaw wraps by default,
because spinning all the way around usually is.

Setting either property applies the limit before touching ``rotation``, so the node can never
hold a value outside its range even for a frame. Turning on ``clamp_yaw`` gives you a turret
with a firing arc.

Doing the maths on ``pitch`` and ``yaw`` rather than on a ``Vector3`` rotation is what avoids
gimbal lock. Set those two properties and leave the node's own rotation alone.
