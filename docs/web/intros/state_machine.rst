A finite state machine built out of nodes, so states are visible in the scene tree, editable in
the inspector, and can hold their own children.

States are direct children of the :ref:`class_FoxStateMachine`. Each is keyed by its
``state_id``, or by its node name when that is left blank.

.. code-block:: text

    Player
    └─ StateMachine        (initial_state -> Idle)
       ├─ Idle
       └─ Running

The important rule is that **a state never switches itself**. It emits
``transition_requested`` and the machine performs the swap. States therefore never hold a
reference to one another, which is what stops a state machine turning into the tangle it was
supposed to replace.

.. code-block:: gdscript

    # idle.gd
    extends FoxState

    func enter() -> void:
        owner.velocity = Vector3.ZERO

    func physics_update(_delta: float) -> void:
        if Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down"):
            transition_requested.emit(self, &"Running")

The machine forwards ``_process`` and ``_physics_process`` to whichever state is active and
nothing else, so an inactive state costs nothing.

A request from a state that is no longer active is ignored. That guard matters more than it
looks: without it, a state that queues a transition and then gets swapped out by something else
would yank the machine somewhere unexpected a frame later.

:ref:`class_FoxState` is abstract, so it cannot be attached to a node directly. Write a subclass
even if three of the four methods are empty.
