Every other module depends on ``core``, and ``core`` depends on nothing.

:ref:`class_FoxNode`, :ref:`class_FoxNode2D`, :ref:`class_FoxNode3D`, :ref:`class_FoxControl`,
:ref:`class_FoxResource` and :ref:`class_FoxRefCounted` extend their engine equivalents without
adding behaviour. They give every type in the library a common ancestor and an editor icon.

The rest is stat maths. :ref:`class_FoxBoundedValue` is a float clamped between a minimum and a
maximum that reports how far past either bound a change tried to go, which can be used for
overkill damage or wasted healing. :ref:`class_FoxModifiableStat` is a base value with named
stacks of flat and multiplier modifiers that can be added and removed individually.
:ref:`class_FoxStatPool` combines the two into a current value bounded by a modifiable maximum,
for health, mana and stamina.

.. code-block:: gdscript

    var attack := FoxModifiableStat.new(100.0)
    attack.add_flat_modifier(&"gear", 50.0)
    attack.add_multiplier_modifier(&"rage", 0.5)
    print(attack.value)  # (100 + 50) * 1.5 = 225

.. note::

    Multipliers are summed on top of ``1.0``. A single ``0.5`` multiplier gives ``+50%``, not
    half.

.. note::

    These are ``Resource`` types. Enable **Local to Scene** when one is assigned to more than
    one instance, otherwise every instance shares a single value.
