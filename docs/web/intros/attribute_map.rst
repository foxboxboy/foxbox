Stores arbitrary data, counted flags, and rules that propagate through a node hierarchy.

Any ``Variant`` can be stored under a ``StringName`` key. Keys can be tagged into groups and
retrieved together.

.. code-block:: gdscript

    stats.set_data(&"move_speed", 5.0)
    stats.add_data_to_group(&"move_speed", &"movement")

Flags are counted, not boolean. Two sources of the same flag must both be removed before it
clears.

.. code-block:: gdscript

    stats.increment_flag(&"slowed")
    stats.increment_flag(&"slowed")
    stats.decrement_flag(&"slowed")
    stats.has_flag(&"slowed")         # true, one stack remains

A :ref:`class_FoxAttributeRule` is a reversible modification to one key. Adding one applies it to
this map and every child map beneath it. ``can_receive_rules`` and ``can_send_rules`` control
inheritance in each direction.

Maps locate their parent on entering the tree, and a map that joins later receives existing rules
and flags.

.. note::

    ``can_receive_rules`` only affects inherited rules. ``add_rule`` called directly always
    applies.
