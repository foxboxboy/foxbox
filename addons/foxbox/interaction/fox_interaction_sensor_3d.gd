class_name FoxInteractionSensor3D
extends Node3D
## Raycast manager for finding a FoxInteractable3D.

## Uses a Raycast3D and finds if it is colliding with a FoxInteractable3D.

## Emitted when the sensor starts looking at an interactable.
signal focused(interactable: FoxInteractable3D)
## Emitted when the sensor is no longer looking at an interactable.
signal unfocused(interactable: FoxInteractable3D)

@export var raycast : RayCast3D
@export var interaction_range: float = 2.5
@export var search_mode := SearchMode.SINGLE

var _current_target: FoxInteractable3D = null

enum SearchMode{
	## Checks if just the first collider is a FoxInteractable3D.
	SINGLE,
	## Checks if one of the collider's children are a FoxInteractable3D.
	CHILDREN,
	## Checks if one of the collider's descendants are a FoxInteractable3D.
	DESCENDANTS,
}


#region Built-In

func _ready() -> void:
	raycast.enabled = true
	# Negative Z is "Forward" in Godot 3D
	raycast.target_position = Vector3(0, 0, -interaction_range)


func _physics_process(_delta: float) -> void:
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		
		# We check if the object HAS the interactable component
		# This is the "Closed" check—it doesn't care WHAT the object is.
		var interactable := _find_interactable(collider, search_mode == SearchMode.CHILDREN)
		
		if interactable and _current_target != interactable:
			_current_target = interactable
			focused.emit(_current_target)
		elif not interactable and _current_target != null:
			_clear_target()
	elif _current_target != null:
		_clear_target()

#endregion





#region Public

func get_current_target() -> FoxInteractable3D:
	return _current_target

func set_target_position(new_target_position: Vector3) -> void:
	raycast.target_position = new_target_position


func get_target_position() -> Vector3:
	return raycast.target_position

#endregion





#region Private

func _find_interactable(node: Node, check_children := false) -> FoxInteractable3D:
	# Check the collider itself or its children for the component
	if node is FoxInteractable3D:
		return node
	
	if check_children:
		for child in node.get_children():
			if child is FoxInteractable3D:
				return child
			if search_mode == SearchMode.DESCENDANTS:
				_find_interactable(child, true)
	
	return null


func _clear_target() -> void:
	var _old_target := _current_target
	_current_target = null
	unfocused.emit(_old_target)

#endregion
