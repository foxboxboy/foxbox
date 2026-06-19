class_name FoxGroundState
extends FoxState
## Applies floor-based speed and direction to a FoxCharacterMotor3D.

@export var motor: FoxCharacterMotor3D

## Pushed by the project's brain every frame
var current_speed: float = 5.0
var input_direction: Vector2 = Vector2.ZERO

func _ready() -> void:
	state_id = &"Ground"

func enter() -> void:
	motor.enable()

func exit() -> void:
	motor.disable()

func update(_delta: float) -> void:
	pass

func physics_update(delta: float) -> void:
	motor.speed = current_speed
	motor.input_direction = input_direction
	
	#motor._physics_process(delta)
