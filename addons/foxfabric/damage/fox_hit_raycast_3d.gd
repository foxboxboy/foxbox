@icon("uid://oit74etj11kg")
class_name FoxHitRayCast3D
extends RayCast3D
## Delivers a [Variant] payload to the first [FoxHurtArea3D] it strikes.
##
## Acts as the hitscan trigger for the FoxFabric interaction pipeline.
## [br][b]Note:[/b] Ensure [member collide_with_areas] is enabled in the inspector.


## Emitted when this raycast successfully delivers its [param payload] to a [param target].
signal hit_delivered(payload: Variant, target: FoxHurtArea3D)

## The arbitrary data this raycast will deliver upon intersection.
## Set this via your game's weapon or interaction scripts.
@export var payload: Variant


## Forces the raycast to update immediately and attempts to deliver the [member payload].
func fire() -> void:
	force_raycast_update()
	
	if not is_colliding():
		return
		
	var collider := get_collider()
	var hurtbox := collider as FoxHurtArea3D
	
	if not hurtbox:
		return
		
	hurtbox.receive_hit(payload)
	hit_delivered.emit(payload, hurtbox)
