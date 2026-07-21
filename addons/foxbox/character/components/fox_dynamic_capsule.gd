class_name FoxDynamicCapsule
extends CollisionShape3D

## Smoothly animates the capsule's height while 
## automatically adjusting its Y-position to keep the base grounded.

@export var transition_time: float = 0.2

func lerp_height_to(target_height: float) -> void:
	if not shape is CapsuleShape3D:
		push_warning("FoxDynamicCapsule requires a CapsuleShape3D.")
		return
		
	var target_y: float = target_height / 2.0
	var tween := create_tween().set_parallel(true)
	
	tween.tween_property(shape, "height", target_height, transition_time)
	tween.tween_property(self, "position:y", target_y, transition_time)
