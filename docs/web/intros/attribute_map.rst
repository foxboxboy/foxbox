A per-entity data store that other systems read and write without holding references to each
other. It handles arbitrary data, stacked flags, and rules that propagate through a node
hierarchy.

Any ``Variant`` can be stored under a ``StringName`` key, and keys can be tagged into groups and
retrieved together.

.. code-block:: gdscript

    var stats := $AttributeMap as FoxAttributeMap
    stats.set_data(&"health", FoxStatPool.new())
    stats.set_data(&"move_speed", 5.0)
    stats.add_data_to_group(&"move_speed", &"movement")

Flags are counted rather than boolean, so two sources of the same condition must both end before
the flag clears.

.. code-block:: gdscript

    stats.increment_flag(&"slowed")   # swamp
    stats.increment_flag(&"slowed")   # frost spell
    stats.decrement_flag(&"slowed")   # left the swamp
    stats.has_flag(&"slowed")         # true, one stack remains

A :ref:`class_FoxAttributeRule` is a reversible modification to one key. Adding a rule applies it
to that map and to every child map beneath it, so a vehicle can modify everything riding in it.
Set ``can_receive_rules`` to ``false`` on a child to opt out, or ``can_send_rules`` to ``false``
on a parent to stop it broadcasting.

Maps locate their parent when they enter the tree, and a map that joins later receives the rules
and flags that already exist. A map created while the tree is not live will not link up.

.. note::

    ``can_receive_rules`` only affects inherited rules. Calling ``add_rule`` directly on a map
    always applies.
