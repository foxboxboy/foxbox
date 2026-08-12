:github_url: hide

Aim Gimbal
==========

Turns mouse or stick movement into pitch and yaw, with limits on each. Pitch and yaw are separate nodes.

Accumulates 2D input into pitch and yaw.

.. code-block:: gdscript

    $Gimbal.yaw -= event.relative.x * sensitivity
    $Gimbal.pitch -= event.relative.y * sensitivity

Each axis independently clamps or wraps. Pitch clamps by default, yaw wraps. Setting either
applies the limit before writing to ``rotation``.

.. note::

    Set ``pitch`` and ``yaw`` rather than ``rotation``. That is what avoids gimbal lock.

.. toctree::
   :maxdepth: 1

   class_foxaimgimbal3d
