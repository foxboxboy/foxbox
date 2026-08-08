# A prop that can be picked up. Answers an interaction by asking whoever poked it to carry it.
extends RigidBody3D

## Passed straight to the dragger. Leave it null to use the dragger's own defaults.
@export var drag_profile: FoxPhysicsDragProfile

## Shown in the readout so you can tell what you are pointing at.
@export var label: String = "prop"


## The module has no idea what interacting means, so the prop decides. Here it means "pick me
## up", which the initiator is the one able to actually do.
## [br][br]
## Asked for by name rather than by type, so the prop stays ignorant of who is carrying it. That
## is the whole point of the interaction module handing over an arbitrary context.
func _on_interacted(interactor: Variant) -> void:
	var hands: Node = interactor as Node
	if hands != null and hands.has_method(&"grab_body"):
		hands.call(&"grab_body", self, drag_profile)
