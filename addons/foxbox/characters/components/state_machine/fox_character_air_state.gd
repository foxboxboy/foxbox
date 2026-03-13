class_name FoxCharacterAirState
extends FoxCharacterState

## A state that handles falling, coyote time, and multiple mid-air jumps.

#region Exports

@export var state_id: StringName = &"Air"
@export var motor: FoxCharacterMotor3D 

#endregion





#region State Virtual Methods

## Called by the state machine when leaving the ground.
## Validates dependencies, enables the motor, and syncs the visual pose to the air state.
func enter() -> void:
	assert(motor != null, "AirState requires a FoxCharacterMotor3D.")
	assert(character != null, "AirState requires a FoxCharacter.")
	
	motor.enable()
	character.enter_air()


## Called by the state machine upon landing or dashing.
## Disables the physics motor to hand control to the next state.
func exit() -> void:
	motor.disable()


## Called every visual frame by the state machine.
func update(_delta: float) -> void:
	pass


## Acts as the primary orchestrator for the mid-air execution loop. 
## Evaluates state transitions, synchronizes visual models, and drives the physics motor.
func physics_update(delta: float) -> void:
	var transitioned := _check_and_handle_transitions()
	if transitioned: return
		
	character.update_locomotion_visuals()
	_execute_motor(delta)

#endregion





#region Internal Helpers

## Evaluates current intents and physical states to determine if the state machine should transition.
## Returns [code]true[/code] if a transition was requested, signaling the physics loop to abort early.
func _check_and_handle_transitions() -> bool:
	
	# Priority 1: Dashing
	if character.has_dash_request() and character.can_dash():
		character.consume_dash_request()
		transition_requested.emit(self, &"Dash")
		return true
		
	# Priority 2: Landing
	# We check downward velocity to prevent snapping to the ground while moving up a steep slope.
	if motor.body.velocity.y <= 0.0 and not character.is_in_air():
		transition_requested.emit(self, &"Grounded")
		return true
	
	# Priority 3: Mid-Air Jumping
	if character.has_jump_request() and _can_jump_in_air():
		_execute_jump()
		return false

	return false


## Evaluates if the character has remaining jump charges or is within the coyote time window.
func _can_jump_in_air() -> bool:
	return character.can_coyote_jump() or character.can_multi_jump()


## Consumes a validated jump request, increments jump memory, and applies vertical impulse.
func _execute_jump() -> void:
	character.consume_jump_request()
	
	motor.jump()
	character.jumped.emit(1.0)


## Passes the character's desired input direction to the motor and advances its simulation.
func _execute_motor(delta: float) -> void:
	motor.input_direction = character.input_direction
	motor._physics_process(delta)

#endregion
