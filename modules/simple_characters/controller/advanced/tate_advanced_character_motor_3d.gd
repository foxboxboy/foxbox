extends TateCharacterMotor3D
class_name TateAdvancedCharacterMotor3D
## A more advanced and robust character motor. Less flexible for a greater variety
## of games but designed to have generic behavior and features built in that many 
##games/projects require (better jumping, interacting, sprinting, etc).

@export_group("Advanced Jump")
## (Optional) Raycast3D that detects if the body is on the ground.
## Exists to allow more responsive jumping.
@export var ground_cast : RayCast3D
## (Optional) The max time spent in the air before a player can no
## longer jump. 
@export var coyote_time := 0.3
@export var can_double_jump := false

var _air_time_elapsed := 0.0
var _has_jumped := false
var _has_double_jumped := false

func _process(delta: float) -> void:
	if not ground_cast.is_colliding():
		_air_time_elapsed += delta
		_air_time_elapsed = clampf(_air_time_elapsed, 0.0, coyote_time * 2)
	else:
		_air_time_elapsed = 0.0


## More advanced can_jump() that checks for a ground cast. 
func can_jump():
	if body.is_on_floor():
		_has_jumped = false
		_has_double_jumped = false
	if ground_cast != null:
		if not _has_jumped:
			return _air_time_elapsed < coyote_time
		elif can_double_jump:
			if not _has_double_jumped:
				return true
	else:
		return super.can_jump()


func jump():
	if not _jump_pressed:
		body.velocity.y = jump_strength
		_jump_pressed = true
		
		if _has_jumped:
			_has_double_jumped = true
		
		jumped.emit()
		
	_has_jumped = true
