class_name FoxInteractable3D
extends Area3D
## A physical volume that can be detected by a FoxInteractionRaycast3D.

## Designed to be extended or used in conjuction with signals on a project basis.

## Emitted when interact() is called.
signal interacted(interactor: Node)
## Emitted when a FoxInteractionRaycast3D focuses this FoxInteractable3D.
signal focused(interaction_raycast : FoxInteractionRaycast3D)
## Emitted when a FoxInteractionRaycast3D unfocuses this FoxInteractable3D.
signal unfocused(interaction_raycast : FoxInteractionRaycast3D)

## Pass in who interacted with it as interactor.
func interact(interactor: Node) -> void:
	interacted.emit(interactor)
	_on_interact(interactor)

func focus(interaction_raycast: FoxInteractionRaycast3D) -> void:
	focused.emit(interaction_raycast)

func unfocus(interaction_raycast: FoxInteractionRaycast3D) -> void:
	unfocused.emit(interaction_raycast)

## Override this function ifor inherited scripts.
func _on_interact(_interactor: Node) -> void:
	pass
