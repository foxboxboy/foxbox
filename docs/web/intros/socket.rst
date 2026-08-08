A named slot that holds one node, reparenting it and optionally snapping its transform. Use it
for vehicle seats, weapon mounts, held items or grid cells. This is the only spatial module with
a full 2D counterpart, and :ref:`class_FoxSocket2D` and :ref:`class_FoxSocketMap2D` mirror the 3D
classes.

:ref:`class_FoxSocket3D` extends ``Marker3D``. ``snap_position``, ``snap_rotation`` and
``snap_scale`` are independent, so a node can be positioned without forcing its rotation. A
socket watches its own children, and if the attachment is reparented elsewhere without calling
``detach`` the socket clears itself rather than holding a stale reference.

:ref:`class_FoxSocketMap3D` collects the sockets beneath it and provides occupancy queries and
automatic placement.

.. code-block:: gdscript

    var seats := $Vehicle/Seats as FoxSocketMap3D

    if seats.attach(player):              # first free socket
        player.set_physics_process(false)

    seats.attach(player, &"DriverSeat")   # a specific socket
    seats.get_available_socket_count()

``detach`` unplugs the node but does not reparent it, so move it yourself afterwards.

.. code-block:: gdscript

    var rider := seats.get_socket(&"DriverSeat").detach()
    rider.reparent(get_tree().current_scene)

.. note::

    A map collects its sockets when it enters the tree. Sockets created after that are not
    registered.
