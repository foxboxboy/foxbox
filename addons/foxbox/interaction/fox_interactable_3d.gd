class_name FoxInteractable3D
extends FoxNode3D

## Signal emitted when the interaction is triggered.
signal interacted()

@export var context_node : Node

func interact() -> void:
	interacted.emit()
	_on_interact()


## Override this function in your inherited scripts.
func _on_interact() -> void:
	pass
