@icon("uid://d1kwkeuoiwmv")
class_name FoxInteractableArea2D
extends Area2D
## A physical volume that can be detected and interacted with.
##
## Designed to be extended or used in conjunction with signals. It accepts a generic
## [Variant] context during interaction, allowing the initiator to pass a [Node],
## a Dictionary of parameters, or a custom context object.




#region Signals

## Emitted when [method interact] is called. The [param context] contains data passed by the initiator.
signal interacted(context: Variant)

## Emitted when a sensor (like a RayCast or Area2D) focuses this object.
signal focused(sensor: Node)

## Emitted when a sensor unfocuses this object.
signal unfocused(sensor: Node)

#endregion




#region Public API

## Triggers the interaction logic.
## Pass any required data (like the player node or a context object) as the [param context].
func interact(context: Variant = null) -> void:
	interacted.emit(context)
	_interact(context)


## Called automatically by an external sensor when this object is hovered or targeted.
func focus(sensor: Node) -> void:
	focused.emit(sensor)
	_focus(sensor)


## Called automatically by an external sensor when this object is no longer targeted.
func unfocus(sensor: Node) -> void:
	unfocused.emit(sensor)
	_unfocus(sensor)

#endregion




#region Virtual Methods

## Virtual method to be overridden in inherited scripts to define custom interaction logic.
func _interact(_context: Variant) -> void:
	pass


## Virtual method to be overridden in inherited scripts to define custom focus (hover) behavior.
func _focus(_sensor: Node) -> void:
	pass


## Virtual method to be overridden in inherited scripts to define custom unfocus behavior.
func _unfocus(_sensor: Node) -> void:
	pass

#endregion
