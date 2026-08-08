A blackboard for an entity. Anything can read or write it without the writer and the reader
knowing about each other, which is what keeps an AI, a UI bar and a status effect from all
needing a direct reference to your player script.

It does three separate jobs.

**Arbitrary data, optionally grouped.** Store any ``Variant`` under a ``StringName`` key, then
tag keys into groups so you can pull related values in one call.

.. code-block:: gdscript

    var stats := $AttributeMap as FoxAttributeMap
    stats.set_data(&"health", FoxStatPool.new())
    stats.set_data(&"move_speed", 5.0)
    stats.add_data_to_group(&"move_speed", &"movement")

**Stacked flags, not booleans.** This is the part people get wrong when they build it
themselves. Two independent sources of "slowed" both have to end before the entity stops being
slowed. A boolean cannot express that, so flags here are counted.

.. code-block:: gdscript

    stats.increment_flag(&"slowed")   # walked into a swamp
    stats.increment_flag(&"slowed")   # and got hit by a frost spell
    stats.decrement_flag(&"slowed")   # left the swamp
    stats.has_flag(&"slowed")         # still true, the spell holds the last stack

**Rules that propagate down a hierarchy.** A :ref:`class_FoxAttributeRule` is a reversible
modification to one key. Add one to a parent map and it reaches every child map beneath it, so
a vehicle can slow everything riding in it without knowing what the passengers are.

Children opt out with ``can_receive_rules``, and parents stop broadcasting with
``can_send_rules``. Note that ``can_receive_rules`` only governs *inherited* rules. Calling
``add_rule`` directly on a map always applies, whatever the flag says.

Maps find their parent when they enter the tree, and a map joining late still picks up rules and
flags that already exist. That does mean a map added while the tree is not live will not link
up, which is worth remembering if you build entities purely in code.
