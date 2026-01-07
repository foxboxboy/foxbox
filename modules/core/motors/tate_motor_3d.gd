@abstract
# tates_lib/modules/core/motors/tate_motor_3d.gd
extends TateNode3D
class_name TateMotor3D

## The raw direction we want to move.
var input_direction := Vector2.ZERO
## The strength (0.0 to 1.0).
var input_strength := 1.0

## Virtual function for "Actions" like Jumping or Turbo.
func perform_action(action_name: String) -> void:
	pass
