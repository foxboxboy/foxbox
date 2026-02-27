class_name FoxInteractable3D
extends Area3D
## A physical volume that can be detected by a [FoxInteractionRaycast3D].
##
## Designed to be extended or used in conjunction with signals on a project basis.





#region Signals

## Emitted when [method interact] is called.
signal interacted(interactor: Node)

## Emitted when a [FoxInteractionRaycast3D] focuses this object.
signal focused(interaction_raycast: FoxInteractionRaycast3D)

## Emitted when a [FoxInteractionRaycast3D] unfocuses this object.
signal unfocused(interaction_raycast: FoxInteractionRaycast3D)

#endregion





#region Public API

## Triggers the interaction logic. 
## Pass the node that initiated the interaction as the [param interactor].
func interact(interactor: Node) -> void:
	interacted.emit(interactor)
	_on_interact(interactor)


## Called automatically by a [FoxInteractionRaycast3D] when hovered.
func focus(interaction_raycast: FoxInteractionRaycast3D) -> void:
	focused.emit(interaction_raycast)


## Called automatically by a [FoxInteractionRaycast3D] when unhovered.
func unfocus(interaction_raycast: FoxInteractionRaycast3D) -> void:
	unfocused.emit(interaction_raycast)

#endregion





#region Virtual Methods

## Virtual method to be overridden in inherited scripts to define custom interaction logic.
func _on_interact(_interactor: Node) -> void:
	pass

#endregion
