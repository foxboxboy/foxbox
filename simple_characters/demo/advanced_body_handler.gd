extends TateBodyHandler
class_name TateAdvancedBodyHandler
## Handles camera in addition to just moving the body around.


## (Optional) Raycast3D that detects if the body is on the ground.
## Exists to allow more responsive jumping.
@export var ground_cast : RayCast3D


## More advanced can_jump() that checks for a ground cast. 
func can_jump():
	if ground_cast:
		return ground_cast.is_colliding()
	else:
		return is_on_floor()
