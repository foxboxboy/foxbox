class_name FoxCharacterDashState
extends FoxCharacterState

## A state that handles a quick, directional burst of movement, ignoring gravity.

#region Exports

@export_group("Dependencies")
@export var state_id: StringName = &"Dash"
@export var motor: FoxCharacterMotor3D

@export_group("Dash Parameters")
## Speed of the dash burst in meters per second.
@export var dash_speed: float = 20.0
## How long the dash lasts in seconds.
@export var dash_duration: float = 0.2
## How long the character must wait before dashing again in seconds.
@export var cooldown_duration: float = 1.0

#endregion





#region Variables

var _dash_timer: float = 0.0
var _dash_direction: Vector3 = Vector3.ZERO
var _last_dash_time: int = 0

#endregion





#region State Virtual Methods

func enter() -> void:
	if motor:
		motor.enable()
		
	_dash_timer = dash_duration
	_last_dash_time = Time.get_ticks_msec()
	
	model.stand()
	
	# Force the model into max speed so the animation tree plays the sprint cycle
	model.set_move_speed(1.0)
	
	_dash_direction = _get_dash_direction()
	motor.body.velocity = _dash_direction * dash_speed


func exit() -> void:
	# Dampen the exit momentum so the character doesn't fly off like a rocket.
	motor.body.velocity *= 0.5


func update(_delta: float) -> void:
	pass


func physics_update(delta: float) -> void:
	_dash_timer -= delta
	
	# Lock the visuals to sprint for the duration of the dash
	model.set_move_speed(1.0)
	
	# Maintain constant velocity and slide (ignoring motor gravity)
	physics_body.velocity = _dash_direction * dash_speed
	physics_body.move_and_slide()

	if _dash_timer <= 0.0:
		if character.is_in_air():
			transitioned.emit(self, &"Air")
		else:
			transitioned.emit(self, &"Grounded")

#endregion





#region Public

## Called by FoxCharacter.gd to verify if the player is allowed to dash.
func is_cooldown_finished() -> bool:
	if _last_dash_time == 0:
		return true
	
	var elapsed_seconds: float = (Time.get_ticks_msec() - _last_dash_time) / 1000.0
	return elapsed_seconds >= cooldown_duration

#endregion





#region Private

func _get_dash_direction() -> Vector3:
	var input: Vector2 = character.input_direction 
	
	if input.length() > 0.1:
		# Dash toward input direction relative to character's global rotation
		return (character.global_basis * Vector3(input.x, 0, -input.y)).normalized()
	
	# Otherwise, dash straight forward
	return -character.global_basis.z

#endregion
