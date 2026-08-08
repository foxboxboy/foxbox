A named slot that holds exactly one node, reparenting it and snapping its transform.

Seats in a vehicle, weapon mounts on a ship, a hand that can hold one item, or a grid cell that
accepts one placed object. Anywhere you need "this spot is either empty or has exactly one thing
in it", plus the bookkeeping to answer which.

This is the only spatial module with a full 2D counterpart. :ref:`class_FoxSocket2D` and
:ref:`class_FoxSocketMap2D` mirror the 3D versions exactly.

A single socket
---------------

:ref:`class_FoxSocket3D` extends ``Marker3D``. Attaching reparents the node under the socket and
optionally snaps position, rotation and scale to the socket's marker. The three snap toggles are
independent, so you can align a rider's position without forcing its rotation.

It also watches its own children. If something reparents the attachment away without going
through ``detach``, the socket notices and clears itself rather than holding a stale reference.

A map of sockets
----------------

:ref:`class_FoxSocketMap3D` collects every socket beneath it and gives you occupancy queries and
automatic placement.

.. code-block:: gdscript

    var seats := $Vehicle/Seats as FoxSocketMap3D

    # take any free seat, or name one explicitly
    if seats.attach(player):
        player.set_physics_process(false)
    seats.attach(player, &"DriverSeat")

    seats.get_available_socket_count()

Two things to know
------------------

``detach`` unplugs the node but deliberately **does not reparent it**. It stays where it is
until you move it, because the socket has no idea where it should go instead.

.. code-block:: gdscript

    var rider := seats.get_socket(&"DriverSeat").detach()
    rider.reparent(get_tree().current_scene)

A map collects its sockets when it enters the tree. Sockets created at runtime after that are
not registered, which matters if you are building slots procedurally.
