:github_url: hide

State Machine
=============

States as child nodes. The machine forwards process, physics, and input to whichever one is current, and states ask it to change.

States are direct children of the :ref:`class_FoxStateMachine`, keyed by ``state_id`` or by node
name if ``state_id`` is empty.

A state does not change the active state itself. It emits ``transition_requested`` and the machine
performs the swap.

.. code-block:: gdscript

    extends FoxState

    func physics_update(_delta: float) -> void:
        if Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down"):
            transition_requested.emit(self, &"Running")

The machine forwards ``_process`` and ``_physics_process`` only to the active state. A transition
requested by a state that is no longer active is ignored.

.. note::

    :ref:`class_FoxState` is abstract and cannot be attached to a node directly.

.. toctree::
   :maxdepth: 1

   class_foxstate
   class_foxstatemachine
