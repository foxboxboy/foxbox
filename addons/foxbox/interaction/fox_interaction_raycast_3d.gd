class_name FoxInteractionRaycast3D
extends RayCast3D
## A specialized raycast for detecting and managing focus on [FoxInteractable3D] nodes.
##
## [b]Note:[/b] Ensure the raycast's Collision Mask is set only to your Interactables physics layer for optimal performance.





#region Signals

## Emitted when a [FoxInteractable3D] enters focus.
signal focused(interactable: FoxInteractable3D)

## Emitted when a [FoxInteractable3D] leaves focus.
signal unfocused(interactable: FoxInteractable3D)

## Emitted when the [member interaction_range] is modified.
signal interaction_range_changed(new_range: float)

#endregion





#region Variables 

## How far the raycast will project along the local -Z axis. 
## Leave as -1.0 to ignore and use the manual [member RayCast3D.target_position].
@export var interaction_range: float = -1.0:
	set(value):
		if value < 0.0 and value != -1.0:
			push_warning("FoxInteractionRaycast3D: interaction_range set to a negative value (%s). Use -1.0 to ignore." % value)
			
		interaction_range = value
		
		if interaction_range != -1.0:
			target_position = Vector3(0, 0, -interaction_range)
			
		interaction_range_changed.emit(value)

var _current_target: FoxInteractable3D = null

#endregion





#region Public API

## Returns the [FoxInteractable3D] currently being hovered over, or [code]null[/code] if none.
func get_current_target() -> FoxInteractable3D:
	return _current_target

#endregion





#region Private Logic

func _ready() -> void:
	enabled = true


func _physics_process(_delta: float) -> void:
	if is_colliding():
		var interactable = get_collider() as FoxInteractable3D
		
		# Check if we're looking at something new (or if we hit a wall and interactable became null)
		if interactable != _current_target:
			if _current_target:
				_clear_target()
			
			if interactable:
				_current_target = interactable
				focused.emit(_current_target)
				_current_target.focus(self)
			
	elif _current_target != null:
		_clear_target()


func _clear_target() -> void:
	if _current_target:
		_current_target.unfocus(self)
		unfocused.emit(_current_target)
		_current_target = null

#endregion
