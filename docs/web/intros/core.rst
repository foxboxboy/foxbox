Every other module depends on this one and nothing else. It holds two unrelated things.

**Base classes.** :ref:`class_FoxNode`, :ref:`class_FoxNode2D`, :ref:`class_FoxNode3D`,
:ref:`class_FoxControl`, :ref:`class_FoxResource` and :ref:`class_FoxRefCounted` are thin
subclasses of their engine equivalents. They add no behaviour. They exist so that every type in
the library shares an ancestor you can check against, and so each one carries an editor icon
that makes a FoxFabric node recognisable in a crowded scene tree.

**Stat maths.** Three resources that most games rebuild from scratch:

:ref:`class_FoxBoundedValue`
    A float clamped between a minimum and a maximum, which reports how far past the edge a
    change tried to go. That overflow is what lets you build overkill damage or wasted healing
    without tracking it yourself.

:ref:`class_FoxModifiableStat`
    A base value with named stacks of flat and multiplier modifiers on top. Add ``+5`` from a
    ring and ``+10%`` from a buff, then remove exactly the ring's contribution later without
    recalculating anything by hand.

:ref:`class_FoxStatPool`
    The two combined: a current value bounded by a maximum that is itself modifiable. This is
    the shape of health, mana, stamina and every other pool with a raisable ceiling.

Worth knowing about the multiplier maths, because it is easy to assume the opposite: multipliers
are summed on top of ``1.0``. A single ``0.5`` multiplier means **+50%**, not half.

.. code-block:: gdscript

    var attack := FoxModifiableStat.new(100.0)
    attack.add_flat_modifier(&"gear", 50.0)
    attack.add_multiplier_modifier(&"rage", 0.5)
    print(attack.value)  # (100 + 50) * 1.5 = 225

These are ``Resource`` types, so remember to tick **Local to Scene** when the same resource is
assigned to more than one instance. Otherwise every enemy shares one health pool.
