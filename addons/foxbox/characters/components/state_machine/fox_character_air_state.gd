class_name FoxCharacterAirState
extends FoxCharacterState

## Handles falling physics, coyote time, and mid-air jumping logic.
## 
## Manages the transition back to grounded states and handles aerial 
## mobility via the assigned motor.

@export var state_id: StringName = &"Air"
@export var motor: FoxCharacterMotor3D 


func enter() -> void:
	assert(motor != null, "FoxCharacterAirState requires a FoxCharacterMotor3D.")
	assert(character != null, "FoxCharacterAirState requires a FoxCharacter.")
	
	motor.enable()
	
	if character.pose:
		character.pose.resolve_pose(false)


func exit() -> void:
	motor.disable()


func update(_delta: float) -> void:
	pass


func physics_update(delta: float) -> void:
	var transitioned := _check_and_handle_transitions()
	if transitioned: return
		
	character.update_locomotion_visuals()
	_execute_motor(delta)


func _check_and_handle_transitions() -> bool:
	if character.dash and character.dash.has_request() and character.dash.is_available():
		transition_requested.emit(self, &"Dash")
		return true
		
	var should_land := motor.body.velocity.y <= 0.0 and not character.is_in_air()
	if should_land:
		transition_requested.emit(self, &"Grounded")
		return true
	
	var while_on_ground := false
	if character.jump and character.jump.has_request() and character.jump.is_available(while_on_ground):
		_execute_jump()
		return false

	return false


func _execute_jump() -> void:
	character.jump.consume()
	motor.jump()
	character.jumped.emit(1.0)


func _execute_motor(delta: float) -> void:
	motor.input_direction = character.input_direction
	motor._physics_process(delta)
