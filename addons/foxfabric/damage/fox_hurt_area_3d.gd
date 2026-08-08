@tool
@icon("uid://bihwfrg2mota4")
class_name FoxHurtArea3D
extends Area3D
## Receives [Variant] payloads from physical interactions and routes them.
##
## Acts as the receiving end of the FoxFabric interaction pipeline. It listens
## for overlapping [FoxHitArea3D] nodes and broadcasts their payload.


## Emitted immediately when a [param payload] is successfully delivered to this area.
signal hit_received(payload: Variant)

## If [code]false[/code], incoming payloads are silently ignored and no signals are emitted.
@export var is_active: bool = true


## Accepts a [Variant] [param payload] from an external source and emits [signal hit_received].
## [br][br]
## Returns [code]true[/code] if the payload was accepted, or [code]false[/code] when
## [member is_active] is off and the payload was ignored. Deliverers check this so they do not
## report a hit that never landed.
func receive_hit(payload: Variant) -> bool:
	if not is_active:
		return false

	hit_received.emit(payload)
	return true




#region Editor

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []

	var has_shape: bool = false
	for child: Node in get_children():
		if child is CollisionShape3D or child is CollisionPolygon3D:
			has_shape = true
			break

	if not has_shape:
		warnings.append("No CollisionShape3D child, so this area has no volume and will never "
			+ "overlap anything.")

	return warnings

#endregion
