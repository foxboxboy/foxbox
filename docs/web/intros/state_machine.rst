A finite state machine where each state is a node, so states are visible in the scene tree and
configurable in the inspector.

States are direct children of the :ref:`class_FoxStateMachine` and are keyed by their
``state_id``, or by their node name if ``state_id`` is empty.

.. code-block:: text

    Player
    └─ StateMachine        (initial_state -> Idle)
       ├─ Idle
       └─ Running

Usage
-----

A state does not change the active state itself. It emits ``transition_requested`` and the
machine performs the swap, so states never hold references to one another.

.. code-block:: gdscript

    # idle.gd
    extends FoxState

    func enter() -> void:
        owner.velocity = Vector3.ZERO

    func physics_update(_delta: float) -> void:
        if Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down"):
            transition_requested.emit(self, &"Running")

The machine forwards ``_process`` and ``_physics_process`` only to the active state.

Notes
-----

A transition requested by a state that is no longer active is ignored. This prevents a state
that has already been swapped out from changing the machine a frame later.

.. note::

    :ref:`class_FoxState` is abstract and cannot be attached to a node directly. Extend it, even
    if most methods are empty.
