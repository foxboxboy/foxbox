extends TateMotor3D
class_name TateCharacterMotor3D
## Moves itself based on an input direction and the strength of the input. 
## Built in speed and jump_strength to control how fast the body moves and
## how high it can jump.

signal jumped

## The body that will be acted upon. If unspecified, the node this is attached to will become the body.
@export var body : CharacterBody3D
## How fast the body will move.
@export var speed := 5.0
## How high the body will jump. Set to zero to disable jumping.
@export var jump_strength := 9.5
@export var gravity_multiplier := 2.5

## Direction the body will move when given input.
#var input_direction := Vector2.ZERO
## How strong the input is, useful for joysticks.
#var input_strength := 1.0

var _jump_pressed := false


func _ready() -> void:
	
	if body == null:
		if is_instance_of(self, CharacterBody3D):
			body = get_node(".")
		elif get_parent() is CharacterBody3D:
			body = get_parent()
		else:
			printerr("ERROR: No physics body was assigned nor could be found for TateCharacterMotor. ",get_path())


func _physics_process(delta):
	_update_movement()
	
	_update_y_velocity(delta)
	
	if body.is_on_floor():
		reset_jump()


func _update_movement():
	var direction = (-global_basis.z * input_direction.y) + (global_basis.x * input_direction.x)
	
	if direction:
		body.velocity.x = direction.x * speed
		body.velocity.z = direction.z * speed
	else:
		body.velocity.x = move_toward(body.velocity.x, 0.0, speed)
		body.velocity.z = move_toward(body.velocity.z, 0.0, speed)

	body.move_and_slide()


func _update_y_velocity(delta):
	if not body.is_on_floor():
		body.velocity += body.get_gravity() * delta * gravity_multiplier


func jump():
	if not _jump_pressed:
		body.velocity.y = jump_strength
		_jump_pressed = true
		jumped.emit()


func reset_jump():
	_jump_pressed = false


func can_jump() -> bool:
	return body.is_on_floor()
