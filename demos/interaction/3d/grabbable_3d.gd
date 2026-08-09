# A prop that can be picked up.
class_name DemoGrabbable3D
extends RigidBody3D

## Passed straight to the dragger. Leave null to use the dragger's own settings.
@export var drag_profile: FoxPhysicsDragProfile

## Shown in the readout.
@export var label: String = "prop"


# The interaction module does not define what interacting means, so the prop does. Here it means
# pick me up, and grab_body is called by name so the prop never learns what is carrying it.
func _on_interacted(interactor: Variant) -> void:
	if not interactor is Node:
		return

	# Through a typed local, because casting a Variant is what the unsafe_cast warning is about.
	var hands: Node = interactor
	if hands.has_method(&"grab_body"):
		hands.call(&"grab_body", self, drag_profile)
