Socket
======

A spatial occupancy and reparenting system that allows for safely attaching nodes to defined "seats."

A slot that holds one node, reparenting it and optionally snapping its transform.
:ref:`class_FoxSocket2D` and :ref:`class_FoxSocketMap2D` mirror the 3D classes.

:ref:`class_FoxSocket3D` extends ``Marker3D``. ``snap_position``, ``snap_rotation`` and
``snap_scale`` are independent. A socket watches its own children, and clears itself if the
attachment is reparented elsewhere without calling ``detach``.

:ref:`class_FoxSocketMap3D` collects the sockets beneath it.

.. code-block:: gdscript

    seats.attach(node)                    # first free socket
    seats.attach(node, &"DriverSeat")     # a specific socket
    seats.get_available_socket_count()

``detach`` returns the node but does not reparent it.

.. code-block:: gdscript

    var held := seats.get_socket(&"DriverSeat").detach()
    held.reparent(get_tree().current_scene)

.. note::

    A map collects its sockets on entering the tree. Sockets created after that are not
    registered.

.. toctree::
   :maxdepth: 1

   class_foxsocket2d
   class_foxsocket3d
   class_foxsocketmap2d
   class_foxsocketmap3d
