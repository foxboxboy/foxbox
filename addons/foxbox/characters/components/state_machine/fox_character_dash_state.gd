class_name FoxCharacterDashState
extends FoxCharacterState

@export var state_id: StringName = &"Dash"
@export var motor: FoxCharacterMotor3D

## Speed of the dash burst.
@export var dash_speed := 20.0
## How long the dash lasts in seconds.
@export var dash_duration := 0.2

var _dash_timer := 0.0
var _dash_direction := Vector3.ZERO

func update(_delta: float) -> void:
	pass


func enter() -> void:
	if motor:
		motor.enable()
		_dash_timer = dash_duration
		
		# 1. Determine Direction
		# We dash where the player is currently moving, 
		# or forward if they are standing still.
		_dash_direction = _get_dash_direction()
		
		# 2. Apply Initial Velocity
		motor.body.velocity = _dash_direction * dash_speed

func physics_update(delta: float) -> void:
	_dash_timer -= delta
	
	# While dashing, we maintain constant velocity and ignore gravity.
	# We call move_and_slide manually via the motor to ensure we hit walls.
	motor.body.velocity = _dash_direction * dash_speed
	motor.body.move_and_slide()

	# --- TRANSITION ---
	if _dash_timer <= 0:
		if character.is_in_air():
			transitioned.emit(self, &"Air")
		else:
			transitioned.emit(self, &"Grounded")

func _get_dash_direction() -> Vector3:
	# If there is movement input, dash in that direction.
	# Otherwise, dash in the direction the character is facing.
	var input = character.get_movement_input_vector() # Or your equivalent
	if input.length() > 0.1:
		var dir = (character.global_basis * Vector3(input.x, 0, -input.y)).normalized()
		return dir
	
	return -character.global_basis.z # Forward

func exit() -> void:
	# We can optionaly 'kill' some of the dash momentum here 
	# so the character doesn't fly off like a rocket when the state ends.
	motor.body.velocity *= 0.5
