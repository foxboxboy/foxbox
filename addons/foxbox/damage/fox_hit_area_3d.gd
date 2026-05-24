@icon("uid://n6yl7gwwqebs")
class_name FoxHitArea3D
extends Area3D
## Delivers a [Variant] payload to overlapping [FoxHurtArea3D] nodes.
##
## Can act passively via physics overlaps, or instantly via the [method fire] method.


## Emitted when this hitbox successfully delivers its [param payload] to a [param target].
signal hit_delivered(payload: Variant, target: FoxHurtArea3D)


## The arbitrary data this hitbox will deliver upon intersection.
@export var payload: Variant


## Instantly delivers the payload to all [FoxHurtArea3D] nodes currently inside this area.
## Useful for immediate Area-of-Effect interactions like explosions.
func fire() -> void:
	var overlapping_areas = get_overlapping_areas()
	for area in overlapping_areas:
		_try_deliver_payload(area)


func _ready() -> void:
	area_entered.connect(_on_area_entered)


func _on_area_entered(area: Area3D) -> void:
	_try_deliver_payload(area)


func _try_deliver_payload(area: Area3D) -> void:
	var hurtbox := area as FoxHurtArea3D
	if not hurtbox:
		return
		
	hurtbox.receive_hit(payload)
	hit_delivered.emit(payload, hurtbox)
