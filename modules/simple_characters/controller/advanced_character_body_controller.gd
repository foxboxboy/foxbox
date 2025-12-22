extends TateCharacterMotor
class_name TateAdvancedCharacterMotor
## Complex character.


@export_group("Advanced Jump")
## (Optional) Raycast3D that detects if the body is on the ground.
## Exists to allow more responsive jumping.
@export var ground_cast : RayCast3D
## (Optional) The max time spent in the air before a player can no
## longer jump. 
@export var coyote_time := 0.3

var _air_time_elapsed := 0.0


func _process(delta: float) -> void:
	if not ground_cast.is_colliding():
		_air_time_elapsed += delta
		_air_time_elapsed = clampf(_air_time_elapsed, 0.0, coyote_time * 2)
	else:
		_air_time_elapsed = 0.0


## More advanced can_jump() that checks for a ground cast. 
func can_jump():
	if ground_cast:
		return _air_time_elapsed < coyote_time
	else:
		return super.can_jump()
