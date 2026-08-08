@tool
@icon("uid://dus7rdnmnq7y3")
class_name FoxInteractionRayCast3D
extends RayCast3D
## A specialized raycast for detecting and managing focus on [FoxInteractableArea3D] nodes.
##
## [b]Note:[/b] Ensure the raycast's Collision Mask is set only to your Interactables physics layer for optimal performance.




#region Signals

## Emitted when a [FoxInteractableArea3D] enters focus.
signal focused(interactable: FoxInteractableArea3D)

## Emitted when a [FoxInteractableArea3D] leaves focus.
signal unfocused(interactable: FoxInteractableArea3D)

## Emitted when the [member interaction_range] is modified.
signal interaction_range_changed(new_range: float)

#endregion




#region Variables

## How far the raycast will project along the local -Z axis. 
## Leave as [code]-1.0[/code] to ignore and use the manual [member RayCast3D.target_position].
@export var interaction_range: float = -1.0:
	set(value):
		if value < 0.0 and value != -1.0:
			push_warning("FoxInteractionRayCast3D: interaction_range set to a negative value (%s). Use -1.0 to ignore." % value)
			
		interaction_range = value
		
		if interaction_range != -1.0:
			target_position = Vector3(0, 0, -interaction_range)
			
		interaction_range_changed.emit(value)

var _current_target: FoxInteractableArea3D = null

#endregion




#region Public API

## Returns the [FoxInteractableArea3D] currently being hovered over, or [code]null[/code] if none.
func get_current_target() -> FoxInteractableArea3D:
	return _current_target


## Attempts to interact with the currently focused target, passing the given [param context].
func interact_with_target(context: Variant = null) -> void:
	if is_instance_valid(_current_target):
		_current_target.interact(context)

#endregion




#region Private

func _ready() -> void:
	# @tool runs this in the editor too, where it would touch live state.
	if Engine.is_editor_hint():
		return

	enabled = true


func _physics_process(_delta: float) -> void:
	# @tool runs this in the editor too, where it would touch live state.
	if Engine.is_editor_hint():
		return

	var interactable = get_collider() as FoxInteractableArea3D if is_colliding() else null
	
	if interactable == _current_target:
		return
		
	_clear_target()
	
	if interactable:
		_current_target = interactable
		focused.emit(_current_target)
		_current_target.focus(self)


func _clear_target() -> void:
	if is_instance_valid(_current_target):
		_current_target.unfocus(self)
		unfocused.emit(_current_target)
		
	_current_target = null

#endregion




#region Editor

## [member RayCast3D.collide_with_areas] belongs to the parent class, so it cannot be given a
## setter here. [method Object._set] sees the assignment first; returning [code]false[/code]
## leaves the engine to apply it as normal.
## [br][br]
## The refresh is deferred because this runs before the new value lands, and the warning is
## computed from it.
func _set(property: StringName, _value: Variant) -> bool:
	if property == &"collide_with_areas":
		update_configuration_warnings.call_deferred()

	return false


func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []

	if not collide_with_areas:
		warnings.append("Collide With Areas is disabled, so this will never detect a "
			+ "FoxInteractableArea3D. Interactables are areas, not bodies.")

	return warnings

#endregion
