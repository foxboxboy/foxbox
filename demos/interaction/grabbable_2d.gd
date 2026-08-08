# A prop in the 2D interaction demo. Answers an interaction by asking whoever poked it to drag it.
extends RigidBody2D

## Passed straight to the dragger. Leave it null to use the dragger's own defaults.
@export var drag_profile: FoxPhysicsDragProfile

## Shown in the demo's readout so you can tell what you are pointing at.
@export var label: String = "prop"


func _on_interacted(interactor: Variant) -> void:
	# The module has no idea what interacting means, so the prop decides. Here it means
	# "pick me up", which the initiator is the one able to actually do.
	if interactor is Node and interactor.has_method("grab_body"):
		interactor.grab_body(self, drag_profile)
