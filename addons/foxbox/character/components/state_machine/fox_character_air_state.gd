class_name FoxAirState
extends FoxState
## Applies gravity and aerial steering to the motor.

@export var motor: FoxCharacterMotor3D

@export var gravity_multiplier: float = 1.0
@export var air_control_multiplier: float = 0.5

var input_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	state_id = &"Air"

func enter() -> void:
	motor.enable()
	motor.gravity_multiplier = gravity_multiplier

func exit() -> void:
	motor.disable()
	# Reset gravity for other states
	motor.gravity_multiplier = 1.0


func update(_delta: float) -> void:
	pass


func physics_update(delta: float) -> void:
	# Scale the input by our air control factor
	motor.input_direction = input_direction * air_control_multiplier
	
	motor._physics_process(delta)
