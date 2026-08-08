@tool
@icon("uid://dsm5oq811w0qe")
class_name FoxHitShapeCast3D
extends ShapeCast3D
## Delivers a [Variant] payload to all [FoxHurtArea3D] nodes it strikes.
##
## Acts as a "thick raycast" or swept-shape trigger. Perfect for thick lasers
## or high-speed melee sweeps that might tunnel through standard areas.

## Emitted when this shapecast successfully delivers its [param payload] to a [param target].
signal hit_delivered(payload: Variant, target: FoxHurtArea3D)

## The arbitrary data this shapecast will deliver upon intersection.
@export var payload: Variant


## Forces the shapecast to update immediately and attempts to deliver the [member payload].
func fire() -> void:
	force_shapecast_update()
	
	if not is_colliding():
		return
		
	for i in get_collision_count():
		var collider := get_collider(i)
		var hurtbox := collider as FoxHurtArea3D
		
		# only report a delivery the hurtbox actually accepted
		if hurtbox and hurtbox.receive_hit(payload):
			hit_delivered.emit(payload, hurtbox)




#region Editor

## [member ShapeCast3D.collide_with_areas] belongs to the parent class, so it cannot be given a
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
			+ "FoxHurtArea3D. Hurtboxes are areas, not bodies.")

	# Deliberately no warning for a missing shape. ShapeCast3D already reports that itself.
	return warnings

#endregion
