class_name FoxCharacterGroundedState
extends FoxCharacterState

## Handles all grounded movement logic for a [FoxCharacter].
##
## Responsible for walking, crouching, and sprinting. Reads intents 
## from specialized managers and delegates speed to the assigned motor.

@export var state_id: StringName = &"Grounded"
@export var motor: FoxCharacterMotor3D 


func enter() -> void:
	assert(motor != null, "FoxCharacterGroundedState requires a FoxCharacterMotor3D.")
	assert(character != null, "FoxCharacterGroundedState requires a FoxCharacter.")
	
	motor.enable()
	
	if character.jump:
		character.jump.reset_count()
	
	character.flush_inputs()
	
	if character.pose:
		character.pose.resolve_pose(true)


func exit() -> void:
	motor.disable()


func update(_delta: float) -> void:
	pass


func physics_update(delta: float) -> void:    
	if character.jump:
		character.jump.update_grounded_time()
	
	var transitioned := _check_and_handle_transitions()
	if transitioned: return
		
	_process_stance_and_speed()
	character.update_locomotion_visuals()
	
	_execute_motor(delta)


func _check_and_handle_transitions() -> bool:
	if character.dash and character.dash.has_request() and character.dash.is_available():
		character.dash.consume()
		transition_requested.emit(self, &"Dash")
		return true

	if character.is_in_air():
		transition_requested.emit(self, &"Air")
		return true
		
	var while_on_ground := true
	if character.jump and character.jump.has_request() and character.jump.is_available(while_on_ground):
		_execute_jump()
		transition_requested.emit(self, &"Air")
		return true
		
	return false


func _execute_jump() -> void:
	character.jump.consume()
	
	var multiplier: float = 1.0
	if character.pose and character.pose.current_pose == character.pose.Type.CROUCHING:
		multiplier = character.jump.crouch_multiplier
		
	motor.jump(multiplier)
	character.jumped.emit(multiplier)


func _process_stance_and_speed() -> void:
	character.pose.resolve_pose(true)
	var target_speed: float = character.pose.get_current_speed_limit()
	
	if character.sprint and character.pose.current_pose == character.pose.Type.STANDING:
		var current_vel := character.get_current_velocity()
		
		if character.sprint.has_request() and character.has_move_input():
			if character.sprint.is_below_dropoff(current_vel):
				character.sprint.cancel()
			else:
				target_speed = character.sprint.speed
				
	motor.speed = target_speed


func _execute_motor(delta: float) -> void:
	motor.input_direction = character.input_direction
	motor._physics_process(delta)
