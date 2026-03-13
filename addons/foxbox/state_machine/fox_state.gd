## Base class for all states within a [FoxStateMachine].
##
## Abstract class, defines the standard interface for any state. 
## Custom states should extend this class and override [method enter], 
## [method exit], [method update], and [method physics_update] as needed.
@abstract 
class_name FoxState
extends FoxNode

## Emitted when the state requests a transition to another state.
## [param state] is a reference to the state requesting the transition.
## [param new_state_name] is the string name of the target state (case-insensitive).
signal transition_requested(old_state: FoxState, new_state_name: StringName)

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
