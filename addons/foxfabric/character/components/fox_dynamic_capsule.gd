class_name FoxDynamicCapsule
extends CollisionShape3D

## A specialized [CollisionShape3D] that animates its height while remaining grounded.
##
## [FoxDynamicCapsule] automatically calculates the [member Node3D.position] Y-offset needed to keep the
## base of a [CapsuleShape3D] flush with the floor when its height changes.


## Smoothly interpolates the capsule's height to the [param target_height] over [param duration] seconds.
func lerp_height_to(target_height: float, duration: float = 0.2) -> void:
	if not shape is CapsuleShape3D:
		push_warning("FoxDynamicCapsule requires a CapsuleShape3D.")
		return

	var target_y: float = target_height / 2.0
	var tween := create_tween().set_parallel(true)

	tween.tween_property(shape, "height", target_height, duration)
	tween.tween_property(self, "position:y", target_y, duration)
