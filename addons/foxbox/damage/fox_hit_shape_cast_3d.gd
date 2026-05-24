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
		
		if hurtbox:
			hurtbox.receive_hit(payload)
			hit_delivered.emit(payload, hurtbox)
