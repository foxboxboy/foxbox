class_name FoxCharacterDashState
extends FoxCharacterState

## A state that handles a quick, directional burst of movement, ignoring gravity.
## Relies on [FoxDashManager] for configuration and cooldown tracking.

@export_group("Dependencies")
@export var state_id: StringName = &"Dash"
@export var motor: FoxAdvancedCharacterMotor3D


var _dash_timer: float = 0.0
var _dash_direction: Vector3 = Vector3.ZERO


func enter() -> void:
	assert(motor != null, "DashState requires a FoxAdvancedCharacterMotor3D.")	
	motor.enable()
	character.stand()
	
	# Consume the intent and trigger the cooldown/signals
	character.dash.consume()
	
	character.dashed.emit()
	
	_dash_timer = character.dash.duration
	_dash_direction = _get_dash_direction()
	
	# Initial burst
	motor.body.velocity = _dash_direction * character.dash.speed


func exit() -> void:
	# Dampen the exit momentum so the character doesn't fly off like a rocket.
	motor.body.velocity *= 0.5


func update(_delta: float) -> void:
	pass


func physics_update(delta: float) -> void:
	_dash_timer -= delta
	
	character.update_locomotion_visuals()
	
	# Maintain constant velocity and slide
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
		# Dash toward input direction relative to character's global rotation
		return (character.global_basis * Vector3(input.x, 0, -input.y)).normalized()
	
	# Otherwise, dash straight forward
	return -character.global_basis.z
