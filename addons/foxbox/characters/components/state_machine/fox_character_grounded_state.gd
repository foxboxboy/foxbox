class_name FoxCharacterGroundedState
extends FoxCharacterState

## Handles all grounded movement logic for a [FoxCharacter].
##
## Responsible for walking, crouching, and sprinting. Reads intents 
## from the character mediator and applies them to the assigned motor.

#region Exports

## The unique identifier used by the FoxStateMachine to register this node.
@export var state_id: StringName = &"Grounded"
## The motor responsible for executing grounded physics calculations.
@export var motor: FoxCharacterMotor3D 

#endregion





#region State Virtual Methods

## Called by the state machine when transitioning into the grounded state.
## Validates required dependencies, enables the motor, resets jump memory, 
## and evaluates the character's physical posture immediately upon landing.
func enter() -> void:
	assert(motor != null, "GroundedState requires a FoxCharacterMotor3D.")
	assert(character != null, "GroundedState requires a FoxCharacter.")
	
	motor.enable()
	
	character.reset_jumps_made()
	
	if character.has_crouch_intent() or not character.can_stand_up():
		character.crouch()
	else:
		character.stand()


## Called by the state machine when transitioning out of the grounded state.
## Disables the motor to hand physics control over to the next state.
func exit() -> void:
	if motor:
		motor.disable()


## Called every visual frame by the state machine.
## Unused in the grounded state, as locomotion is entirely physics-driven.
func update(_delta: float) -> void:
	pass


## Called every physics frame by the state machine.
## Acts as the primary orchestrator for the grounded execution loop. Updates memory, 
## evaluates state transitions, calculates stance and speed, synchronizes visual 
## models, and drives the physics motor.
func physics_update(delta: float) -> void:	
	character.update_grounded_time()
	
	var transitioned := _check_and_handle_transitions()
	if transitioned: return
		
	_process_stance_and_speed()
	character.update_locomotion_visuals()
	
	_execute_motor(delta)

#endregion





#region Private

## Evaluates current intents and physical states to determine if the state machine should transition.
## Checks for dash requests, falling conditions, and jump requests in priority order.
## Returns [code]true[/code] if a transition was requested, signaling the physics loop to abort early.
func _check_and_handle_transitions() -> bool:
	
	# Priority 1: Dashing
	if character.has_dash_request() and character.can_dash():
		character.consume_dash_request()
		transition_requested.emit(self, &"Dash")
		return true

	# Priority 2: Falling
	if character.is_in_air():
		transition_requested.emit(self, &"Air")
		return true
		
	# Priority 3: Jumping
	if character.has_jump_request():
		_execute_jump()
		transition_requested.emit(self, &"Air")
		return true
		
	return false


## Consumes a validated jump request and applies the corresponding vertical impulse to the motor.
## Calculates jump strength based on the current posture, broadcasts the jump event 
## to external listeners, and forces a standing posture upon leaving the ground.
func _execute_jump() -> void:
	character.consume_jump_request()
	
	var multiplier: float = 1.0
	if character.current_pose == character.Pose.CROUCHING:
		multiplier = character.jump_crouch_multiplier
		
	motor.jump(multiplier)
	character.jumped.emit(multiplier)
		
	# 4. Posture Cleanup
	if character.can_stand_up():
		character.stand()


## Evaluates physical ceiling clearance and player intents to set the correct posture and motor speed.
## Processes constraints in strict priority: physical entrapment overrides crouching intents, 
## which override sprinting intents, falling back to a default walk.
func _process_stance_and_speed() -> void:
	
	# Priority 1: Physical Constraints (Overrides all intents)
	if not character.can_stand_up():
		character.crouch()
		motor.speed = character.crouch_speed
		character.cancel_sprint_request() # Can't sprint while trapped
		return
		
	# Priority 2: Crouch Intent
	if character.has_crouch_intent():
		character.crouch()
		motor.speed = character.crouch_speed
		return
		
	# Priority 3: Cancel Sprint
	var trying_to_sprint := character.has_sprint_intent() and character.has_move_input()
	var should_cancel_sprint := character.is_currently_sprinting() and character.is_below_sprint_dropoff()
	
	if trying_to_sprint and should_cancel_sprint:
		character.stand()
		character.cancel_sprint_request()
		motor.speed = character.walk_speed
		return
		
	# Priority 4: Do Sprint
	if trying_to_sprint:
		character.stand()
		motor.speed = character.sprint_speed
		return
		
	# Priority 5: Default (Walking)
	character.stand()
	motor.speed = character.walk_speed


## Passes the character's desired input direction to the motor and advances its physics simulation.
func _execute_motor(delta: float) -> void:
	motor.input_direction = character.input_direction
	motor._physics_process(delta)

#endregion
