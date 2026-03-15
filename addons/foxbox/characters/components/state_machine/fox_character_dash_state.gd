class_name FoxCharacterDashState
extends FoxCharacterState

## Handles a quick, directional burst of movement that ignores gravity.
## Relies on [FoxDashManager] for configuration and state timing.

#region Exports

@export var state_id: StringName = &"Dash"
@export var motor: FoxAdvancedCharacterMotor3D

#endregion


var _dash_timer: float = 0.0
var _dash_direction: Vector3 = Vector3.ZERO


## Configures the dash: enables the motor, consumes the intent, 
## forces a standing pose, and calculates the burst direction.
func enter() -> void:	
	assert(motor != null, "DashState requires a FoxAdvancedCharacterMotor3D.")    
	motor.enable()
	
	# We force the STANDING pose for the duration of the dash.
	# You could also lock this to a custom Pose.DASHING if you add it later.
	if character.pose:
		character.pose.lock_pose(character.pose.Type.STANDING)
	
	# Ability cleanup
	character.dash.consume()
	character.dashed.emit()
	
	# Setup timing and direction
	_dash_timer = character.dash.duration
	_dash_direction = _get_dash_direction()
	
	# Apply the initial kinetic burst
	motor.body.velocity = _dash_direction * character.dash.speed


func exit() -> void:
	if character.pose:
		character.pose.unlock_pose()
		
	motor.disable()
	
	if character.sprint and character.has_move_input():
		character.sprint.request()


func update(_delta: float) -> void:
	pass


## Main dash loop: maintains velocity and checks for expiration.
func physics_update(delta: float) -> void:
	_dash_timer -= delta
	
	character.update_locomotion_visuals()
	
	# Override physics to maintain constant dash velocity
	motor.body.velocity = _dash_direction * character.dash.speed
	motor.body.move_and_slide()
	
	# Check for completion
	if _dash_timer <= 0.0:
		if character.is_in_air():
			transition_requested.emit(self, &"Air")
		else:
			transition_requested.emit(self, &"Grounded")


## Calculates the global direction of the dash based on current input and basis.
func _get_dash_direction() -> Vector3:
	var input: Vector2 = character.input_direction 
	
	if input.length() > 0.1:
		# Project 2D input into 3D space relative to character's global rotation
		return (character.global_basis * Vector3(input.x, 0, -input.y)).normalized()
	
	# Default to dashing forward if no input is provided
	return -character.global_basis.z

#endregion
