Every other module depends on ``core``. ``core`` depends on nothing.

:ref:`class_FoxNode`, :ref:`class_FoxNode2D`, :ref:`class_FoxNode3D`, :ref:`class_FoxControl`,
:ref:`class_FoxResource` and :ref:`class_FoxRefCounted` extend their engine equivalents without
adding behaviour. They provide a common ancestor and an editor icon.

:ref:`class_FoxBoundedValue` clamps a float between a minimum and a maximum and reports how far
past either bound a change tried to go. :ref:`class_FoxModifiableStat` holds a base value with
named stacks of flat and multiplier modifiers. :ref:`class_FoxStatPool` combines both: a current
value bounded by a modifiable maximum.

.. code-block:: gdscript

    var attack: FoxModifiableStat = FoxModifiableStat.new(100.0)
    attack.add_flat_modifier(&"gear", 50.0)
    attack.add_multiplier_modifier(&"rage", 0.5)
    print(attack.value)  # (100 + 50) * 1.5 = 225

.. note::

    Multipliers sum on top of ``1.0``. A ``0.5`` multiplier gives ``+50%``, not half.

.. note::

    These are ``Resource`` types. Enable **Local to Scene** when one is assigned to more than one
    instance.
