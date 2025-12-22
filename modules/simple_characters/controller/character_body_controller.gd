extends CharacterBody3D
class_name TateCharacterMotor
## Moves itself based on an input direction and the strength of the input. 
## Built in speed and jump_strength to control how fast the body moves and
## how high it can jump.

## How fast the body will move.
@export var speed := 5.0
## How high the body will jump. Set to zero to disable jumping.
@export var jump_strength := 9.5
@export var gravity_multiplier := 2.5

## Direction the body will move when given input.
var input_direction := Vector2.ZERO
## How strong the input is, useful for joysticks.
var input_strength := 1.0

var _jump_pressed := false

func _physics_process(delta):
	_update_movement()
	
	_update_y_velocity(delta)
	
	if is_on_floor():
		reset_jump()


func _update_movement():
	#var input_as_3d : Vector3 = -global_basis.z * input_direction
	#var direction : Vector3 = -global_basis.z * input_as_3d * input_strength
	var direction = (-global_basis.z * input_direction.y) + (global_basis.x * input_direction.x)
	
	if direction:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed)
		velocity.z = move_toward(velocity.z, 0.0, speed)

	move_and_slide()


func _update_y_velocity(delta):
	if not is_on_floor():
		velocity += get_gravity() * delta * gravity_multiplier


func jump():
	if not _jump_pressed:
		velocity.y = jump_strength
		_jump_pressed = true


func reset_jump():
	_jump_pressed = false


func can_jump() -> bool:
	return is_on_floor()
