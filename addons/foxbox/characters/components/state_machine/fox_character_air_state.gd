class_name FoxCharacterAirState
extends FoxCharacterState

## Handles falling physics, coyote time, and mid-air jumping logic.
## 
## Manages the transition back to grounded states and handles aerial 
## mobility via the assigned motor.

#region Exports

@export var state_id: StringName = &"Air"
@export var motor: FoxCharacterMotor3D 

#endregion





#region State Virtual Methods

## Enables the motor and forces the pose manager into the aerial configuration.
func enter() -> void:
	assert(motor != null, "FoxCharacterAirState requires a FoxCharacterMotor3D.")
	assert(character != null, "FoxCharacterAirState requires a FoxCharacter.")
	
	motor.enable()
	
	# Force the pose to IN_AIR (passing false for is_grounded)
	if character.pose:
		character.pose.evaluate(false)


func exit() -> void:
	motor.disable()


func update(_delta: float) -> void:
	pass


## Orchestrates the aerial loop: evaluates transitions and drives physics.
func physics_update(delta: float) -> void:
	var transitioned := _check_and_handle_transitions()
	if transitioned: return
		
	character.update_locomotion_visuals()
	_execute_motor(delta)

#endregion





#region Private

## Prioritizes Dash, Landing, and Mid-Air jump requests.
func _check_and_handle_transitions() -> bool:
	# 1. Dashing
	if character.dash and character.dash.has_request() and character.dash.is_available():
		transition_requested.emit(self, &"Dash")
		return true
		
	# 2. Landing
	# We check if we are physically grounded and not currently moving upward.
	var should_land := motor.body.velocity.y <= 0.0 and not character.is_in_air()
	if should_land:
		transition_requested.emit(self, &"Grounded")
		return true
	
	# 3. Mid-Air Jumping (Double Jumps / Multi-Jumps)
	var while_on_ground := false
	if character.jump and character.jump.has_request() and character.jump.is_available(while_on_ground):
		_execute_jump()
		# We return false here because jumping in the air doesn't 
		# leave the Air state, it just resets vertical momentum.
		return false

	return false


## Consumes the jump request and applies impulse via the motor.
func _execute_jump() -> void:
	character.jump.consume()
	motor.jump()
	character.jumped.emit(1.0)


## Drives the motor with the current input direction and advances simulation.
func _execute_motor(delta: float) -> void:
	motor.input_direction = character.input_direction
	motor._physics_process(delta)

#endregion
