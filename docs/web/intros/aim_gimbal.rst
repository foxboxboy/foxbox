Accumulates 2D input into pitch and yaw. Use it for mouse look, turrets, or anything that
rotates on two axes.

Usage
-----

.. code-block:: gdscript

    func _unhandled_input(event: InputEvent) -> void:
        if event is InputEventMouseMotion:
            $Gimbal.yaw -= event.relative.x * sensitivity
            $Gimbal.pitch -= event.relative.y * sensitivity

Each axis independently clamps or wraps. Pitch clamps by default, so a first person camera
cannot roll over the top. Yaw wraps by default. Enable ``clamp_yaw`` to give a turret a firing
arc.

Setting ``pitch`` or ``yaw`` applies the limit before writing to ``rotation``, so the node never
holds an out of range value.

.. note::

    Operating on ``pitch`` and ``yaw`` rather than on the node's ``rotation`` is what avoids
    gimbal lock. Set those two properties and leave ``rotation`` alone.
