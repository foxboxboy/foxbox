class_name FoxDashState
extends FoxState
## Locks the body into a forced trajectory, ignoring standard friction/gravity.

@export var motor: FoxAdvancedCharacterMotor3D

var dash_velocity: Vector3 = Vector3.ZERO

func _ready() -> void:
	state_id = &"Dash"

func enter() -> void:
	motor.enable()

func exit() -> void:
	motor.disable()

func update(_delta: float) -> void:
	pass

func physics_update(_delta: float) -> void:
	# Override standard motor input processing and force the body
	motor.body.velocity = dash_velocity
	motor.body.move_and_slide()
