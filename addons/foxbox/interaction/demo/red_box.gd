# red_box.gd
extends InteractionDemoEntity

@export var drag_component : FoxDraggable3D

func get_drag_component() -> FoxDraggable3D:
	return drag_component

func _on_interactable_interacted() -> void:
	print("Clicked, I am a red box!")
