class_name FoxCharacterGroundedState
extends FoxCharacterState

## Handles all grounded movement logic for a [FoxCharacter].
##
## Responsible for walking, crouching, and sprinting. Reads intents 
## from the character mediator and applies them to the assigned motor.

#region Exports

@export_group("Dependencies")
## The unique identifier used by the FoxStateMachine to register this node.
@export var state_id: StringName = &"Grounded"
## The motor responsible for executing grounded physics calculations.
@export var motor: FoxCharacterMotor3D 

#endregion





#region State Virtual Methods

func enter() -> void:    
	if motor:
		motor.process_mode = Node.PROCESS_MODE_DISABLED
		motor.enable()
		
	# Evaluate posture immediately upon landing/entering
	if character:
		if character.wants_to_crouch or not character.can_stand_up():
			character.crouch()
		else:
			character.stand()
		
		character.force_update_pose()
		character.landed.emit()
		character.jumps_made = 0


func exit() -> void:
	# Clean up so the next state (like Swim or Dash) starts fresh
	if motor:
		motor.disable()


func update(_delta: float) -> void:
	pass


func physics_update(delta: float) -> void:
	if not character or not motor:
		return
	
	character.last_grounded_time = Time.get_ticks_msec()

	# --- 1. TRANSITIONS ---
	# If a transition returns true, we abort the rest of the frame.
	if _check_for_transitions():
		return
		
	# --- 2. POSTURE & SPEED ---
	_process_stance_and_speed()
	
	# --- 3. VISUALS ---
	# Feed the continuous velocity data to the model for the AnimationTree to blend
	if model:
		model.set_move_speed(snappedf(character.get_speed_percent(), 0.1))
		model.set_vertical_speed(motor.body.velocity.y)
	
	# --- 4. EXECUTE MUSCLE ---
	motor.input_direction = character.input_direction
	motor._physics_process(delta)

#endregion





#region Private

## Checks if the character should leave the grounded state.
## Returns true if a transition was emitted.
func _check_for_transitions() -> bool:
	# Priority 1: Dashing (added can_dash check for safety)
	if character.wants_to_dash and character.can_dash():
		character.wants_to_dash = false
		transitioned.emit(self, &"Dash")
		return true

	# Priority 2: Falling (Walked off a ledge)
	print(character.is_in_air())
	
	if character.is_in_air() and character.is_moving_fast_vertically():
		transitioned.emit(self, &"Air")
		return true
		
	# Priority 3: Jumping
	if character.wants_to_jump:
		character.wants_to_jump = false
		character.jumps_made = 1
		character.last_jump_time = Time.get_ticks_msec()
		
		# Apply crouch jump multiplier if applicable
		if character.current_pose == character.Pose.CROUCHING:            
			motor.jump(character.jump_crouch_multiplier)
			character.jumped.emit(character.jump_crouch_multiplier)
		else:
			motor.jump()
			character.jumped.emit(1.0)
			
		# Force the body to stand when leaving the ground (if physically possible)
		if character.can_stand_up():
			character.stand()
		
		transitioned.emit(self, &"Air")
		return true
		
	return false


## Evaluates inputs and ceiling clearance to set the correct pose and motor speed.
func _process_stance_and_speed() -> void:    
	# 1. Crouching Intent
	if character.wants_to_crouch:
		character.crouch()
		motor.speed = character.crouch_speed
		
	# 2. Sprinting Intent
	elif character.wants_to_sprint and character.has_move_input():
		# They must have physical room to stand up in order to sprint
		if character.can_stand_up():
			character.stand()
			
			# Dropoff check: Stop sprinting if they slow down too much
			var sprint_dropoff_threshold: float = character.sprint_speed * character.stop_sprinting_threshold
			if character.get_current_velocity() < sprint_dropoff_threshold:
				character.wants_to_sprint = false
			else:
				motor.speed = character.sprint_speed
			
		else:
			# Trapped under an obstacle, force crouch and cancel sprint intent
			character.crouch()
			motor.speed = character.crouch_speed
			character.wants_to_sprint = false
			
	# 3. Default (Walking)
	else:
		# Always check clearance before standing up
		if character.can_stand_up():
			character.stand()
			motor.speed = character.walk_speed
		else:
			character.crouch()
			motor.speed = character.crouch_speed

#endregion
