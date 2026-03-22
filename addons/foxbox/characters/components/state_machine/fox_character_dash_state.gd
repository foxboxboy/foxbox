class_name FoxCharacterDashState
extends FoxCharacterState

## Handles a quick, directional burst of movement that ignores gravity.
## Relies on [FoxDashManager] for configuration and state timing.

@export var state_id: StringName = &"Dash"
@export var motor: FoxAdvancedCharacterMotor3D

var _dash_timer: float = 0.0
var _dash_direction: Vector3 = Vector3.ZERO


func enter() -> void:    
	assert(motor != null, "FoxCharacterDashState requires a FoxAdvancedCharacterMotor3D.")    
	motor.enable()
	
	if character.pose:
		character.pose.lock_pose(character.pose.Type.STANDING)
	
	character.dash.consume()
	character.dashed.emit()
	
	_dash_timer = character.dash.duration
	_dash_direction = _get_dash_direction()
	
	motor.body.velocity = _dash_direction * character.dash.speed


func exit() -> void:
	if character.pose:
		character.pose.unlock_pose()
		
	motor.disable()
	
	if character.sprint and character.has_move_input():
		character.sprint.request()


func update(_delta: float) -> void:
	pass


func physics_update(delta: float) -> void:
	_dash_timer -= delta
	character.update_locomotion_visuals()
	
	motor.body.velocity = _dash_direction * character.dash.speed
	motor.body.move_and_slide()
	
	if _dash_timer <= 0.0:
		if character.is_in_air():
			transition_requested.emit(self, &"Air")
		else:
			transition_requested.emit(self, &"Grounded")


func _get_dash_direction() -> Vector3:
	var input: Vector2 = character.input_direction 
	if input.length() > 0.1:
		return (character.global_basis * Vector3(input.x, 0, -input.y)).normalized()
		
	return -character.global_basis.z
