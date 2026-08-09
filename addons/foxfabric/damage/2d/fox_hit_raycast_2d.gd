@tool
@icon("uid://cecftfuy1tedf")
class_name FoxHitRayCast2D
extends RayCast2D
## A 2D ray that delivers a [Variant] payload to the first [FoxHurtArea2D] it strikes.
##
## Acts as the hitscan trigger for the FoxFabric damage pipeline.
## [br][b]Note:[/b] Ensure [member RayCast2D.collide_with_areas] is enabled in the inspector.


## Emitted when this raycast successfully delivers its [param payload] to a [param target].
signal hit_delivered(payload: Variant, target: FoxHurtArea2D)

## The arbitrary data this raycast will deliver upon intersection.
## Set this via your game's weapon or interaction scripts.
@export var payload: Variant


## Forces the raycast to update immediately and attempts to deliver the [member payload].
func fire() -> void:
	force_raycast_update()

	if not is_colliding():
		return

	var collider := get_collider()
	var hurtbox := collider as FoxHurtArea2D

	if not hurtbox:
		return

	# only report a delivery the hurtbox actually accepted
	if hurtbox.receive_hit(payload):
		hit_delivered.emit(payload, hurtbox)




#region Editor

## [member RayCast2D.collide_with_areas] belongs to the parent class, so it cannot be given a
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
			+ "FoxHurtArea2D. Hurtboxes are areas, not bodies.")

	# Deliberately no warning for enabled being off. fire() uses force_raycast_update(), which
	# the engine documents as working regardless of enabled.
	return warnings

#endregion
