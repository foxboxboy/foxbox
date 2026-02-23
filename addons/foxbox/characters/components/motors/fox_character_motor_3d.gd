extends FoxNode3D
class_name FoxCharacterMotor3D
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
## How much the default gravity will apply. Makes the character 
## feel more floaty (less than 1) or heavier (greater than 1).  
@export var gravity_multiplier := 2.5

## Direction the body will move when given input.
var input_direction := Vector2.ZERO
## How strong the input is, useful for joysticks.
var input_strength := 1.0
## Whether or not this motor will process. 
## True will set the process mode to Node.PROCESS_MODE_INHERIT.
## False will set the process mode to Node.PROCESS_MODE_DISABLED.
var active := true:
	set(new_value):
		active = new_value
		
		if active:
			process_mode = Node.PROCESS_MODE_INHERIT
		else:
			process_mode = Node.PROCESS_MODE_DISABLED


## Internal variable used to stop the body from jumping over and over. 
## Becomes true when jump() is called and resets to false when the body is on the floor.
var _jump_pressed := false




#region Virtual Methods

func _ready() -> void:
	if not body:
		if is_instance_of(self, CharacterBody3D):
			body = get_node(".")
		elif get_parent() as CharacterBody3D:
			body = get_parent()
		else:
			push_error("ERROR: No physics body was assigned nor could be found for FoxCharacterMotor3D. ",get_path())


func _physics_process(delta) -> void:
	if not body: return
	if not active: return
	
	_update_y_velocity(delta)
	_update_movement(delta)
	
	body.move_and_slide()
	
	if body.is_on_floor():
		reset_jump_pressed()

#endregion





#region Public API

## Enables the motor to work.
## Also sets its process to Node.PROCESS_MODE_INHERIT.
func enable():
	active = true
	


## Enables the motor to work.
## Also sets its process to Node.PROCESS_MODE_DISABLED for performance.
func disable():
	active = false


## Makes the body jump based on jump_strength multiplied by the multiplier passed in.
func jump(multiplier := 1.0) -> void:
	body.velocity.y = jump_strength * multiplier
	_jump_pressed = true
	jumped.emit()


## Sets _jump_pressed to false. 
func reset_jump_pressed() -> void:
	_jump_pressed = false


## Returns true if the body is on the ground and character hasn't already jumped.
func can_jump() -> bool:
	return body.is_on_floor() and not _jump_pressed

#endregion





#region Private Helpers 

func _update_movement(_delta) -> void:
	var direction = (-body.global_basis.z * input_direction.y) + (body.global_basis.x * input_direction.x)
	direction = direction * input_strength
	
	if not input_direction.is_zero_approx():
		body.velocity.x = direction.x * speed
		body.velocity.z = direction.z * speed
	else:
		body.velocity.x = move_toward(body.velocity.x, 0.0, speed)
		body.velocity.z = move_toward(body.velocity.z, 0.0, speed)


func _update_y_velocity(delta) -> void:
	if not body.is_on_floor():
		body.velocity += body.get_gravity() * delta * gravity_multiplier

#endregion
