@icon("uid://bseln2v3x3gem")
@abstract
class_name FoxState
extends FoxNode
## Base class for all states within a [FoxStateMachine].
##
## Custom states should override [method enter], [method exit], 
## [method update], and [method physics_update] as needed.




#region Signals

## Emitted when the state requests a transition to another state.
## [param old_state] is a reference to the state requesting the transition.
## [param new_state_name] is the string name of the target state.
signal transition_requested(old_state: FoxState, new_state_name: StringName)

#endregion




#region Variables

## An optional custom identifier for this state. 
## If left empty, the [FoxStateMachine] will use this node's name instead.
@export var state_id: StringName = &""

#endregion




#region Abstract Methods

## Called by the [FoxStateMachine] when this state becomes the active state.
## Use this to initialize animations, reset variables, or apply initial forces.
@abstract
func enter() -> void


## Called by the [FoxStateMachine] immediately before transitioning away from this state.
## Use this to clean up variables or reset components before the next state takes over.
@abstract
func exit() -> void


## Called every frame by the [FoxStateMachine]'s [method Node._process].
## [param _delta] is the time elapsed since the previous frame.
@abstract
func update(_delta: float) -> void


## Called every physics frame by the [FoxStateMachine]'s [method Node._physics_process].
## [param _delta] is the time elapsed since the previous physics frame.
@abstract
func physics_update(_delta: float) -> void

#endregion
