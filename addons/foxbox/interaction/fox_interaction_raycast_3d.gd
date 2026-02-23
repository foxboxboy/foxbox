class_name FoxInteractionRaycast3D
extends RayCast3D
## Raycast for finding a FoxInteractable3D.

## Ensure the raycast's Collision Mask is set only to your Interactables physics layer.

## Emitted when a FoxInteractable3D enters focus.
signal focused(interactable: FoxInteractable3D)
## Emitted when a FoxInteractable3D leaves focus.
signal unfocused(interactable: FoxInteractable3D)
## Emitted when the interaction_range is changed.
signal interaction_range_changed(new_range : float)

## How far the raycast will project. 
## This just overrides the -z of the target position for abstraction.
## Leave as -1 to ignore. 
@export var interaction_range: float = -1:
	set(value):
		interaction_range = value
		
		if interaction_range != -1:
			target_position = Vector3(0, 0, -interaction_range)
		
		interaction_range_changed.emit(value)


## The FoxInteractable3D being hovered over.
var _current_target: FoxInteractable3D = null


func _ready() -> void:
	enabled = true


func _physics_process(_delta: float) -> void:
	if is_colliding():
		var interactable = get_collider() as FoxInteractable3D
		
		# check if we're looking at something new
		if interactable != _current_target:
			if _current_target:
				_clear_target()
			
			if interactable:
				_current_target = interactable
				focused.emit(_current_target)
				_current_target.focus(self)
			
	elif _current_target != null:
		_clear_target()


## Returns the FoxInteractable3D being hovered over.
func get_current_target() -> FoxInteractable3D:
	print(_current_target)
	return _current_target


## Clears the _current_target.
func _clear_target() -> void:
	if _current_target:
		_current_target.unfocus(self)
		unfocused.emit(_current_target)
		_current_target = null
