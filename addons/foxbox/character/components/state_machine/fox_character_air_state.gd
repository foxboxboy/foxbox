class_name FoxAirState
extends FoxState
## Applies gravity and aerial steering to the motor.

@export var motor: FoxAdvancedCharacterMotor3D

@export var gravity_multiplier: float = 1.0
@export var air_control_multiplier: float = 0.5

var input_direction: Vector2 = Vector2.ZERO
var current_speed: float = 5.0 # Now it can receive the Pawn's speed!

func _ready() -> void:
	state_id = &"Air"

func enter() -> void:
	motor.enable()
	motor.gravity_multiplier = gravity_multiplier

func exit() -> void:
	motor.disable()
	motor.gravity_multiplier = 1.0


func update(_delta: float) -> void:
	pass


func physics_update(_delta: float) -> void:
	# Pass the variables down to the muscle.
	motor.speed = current_speed
	motor.input_direction = input_direction * air_control_multiplier
	
	# We DO NOT call motor.move_and_slide() or motor._physics_process()
	# The motor handles its own execution!
