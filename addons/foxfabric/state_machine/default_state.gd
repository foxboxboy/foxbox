extends FoxState
## A concrete [FoxState] that does nothing.
##
## [FoxState] is abstract, so it cannot be attached to a node directly. Use this when a machine
## needs a placeholder state, such as an idle or disabled state, without writing a script for it.

## Does nothing. Override in a subclass to run logic when this state becomes active.
func enter() -> void:
	pass

## Does nothing. Override in a subclass to run logic when this state is left.
func exit() -> void:
	pass

## Does nothing. Override in a subclass to run per-frame logic.
func update(_delta: float) -> void:
	pass

## Does nothing. Override in a subclass to run per-physics-frame logic.
func physics_update(_delta: float) -> void:
	pass
