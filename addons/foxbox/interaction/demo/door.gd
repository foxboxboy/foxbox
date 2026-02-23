# door.gd
extends RigidBody3D

@export var drag_profile : FoxPhysicsDragProfile


func _on_interactable_area_3d_interacted(interactor: Node) -> void:
	print("Clicked, I am a door!")
	
	if interactor.has_method("drag_target"):
		interactor.drag_target(self, drag_profile)
