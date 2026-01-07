extends TateComponent
class_name TatePhysicsCharacterMotor3D
## Simple character controller for physics based 3D movement.
## Done via a proportional–integral–derivative (PID) controller.

#region Exports

@export_group("Nodes")
## What will be turning. This exists seperate from the rigid_body since
## trying to turn the rigid_body causes all momentum to be lost.
## If we wanted to turn the rigid_body, we would have to use
@export var forward_marker: Marker3D
## The RigidBody that will be moved. Leave blank to make the node attached
## the RigidBody or the parent.
@export var rigid_body : RigidBody3D
## Used to detect if the character is on the floor. Used for jumping.  
@export var jump_cast : RayCast3D


@export_group("Speed")
## The speed the character is trying to reach.
@export var target_speed := 5.0
## How quickly the target_speed will be reached.
@export var acceleration := 0.5
var jump_force := 600.0

@export_group("PID Settings")
## Proportional. Further you are from the target, the harder you push.
## Increase for snappiness/responsiveness.
@export var p := 60.0
## Integral. Fixes small errors that build up over time.
@export var i := 0.1
## Derivative. Acts as a damper to prevent jittering.
@export var d := 1.0


#endregion





#region Variables

## Direction the character should be moving. Applied based on
## the visual_body. For example, applying (1,0) will move the rigid_body
## in the forward direction of the visual_body.
var input_direction := Vector2.ZERO
## A number between 0 and 1 of how strong the input is.
var input_strength := 0.0
## The PID controller used by this character.
var _pid := Pid3D.new(60.0, 0.1, 1.0)

var has_jumped := false

#endregion




#region Built-In

func _ready() -> void:
	if rigid_body == null:
		rigid_body = _find_rigid_body()
	
	assert(forward_marker != null, "ERROR: No forward_marker was assigned for TatePhysicsCharacterMotor. "+str(get_path()))
	assert(jump_cast != null, "ERROR: No jump_cast was assigned for TatePhysicsCharacterMotor. "+str(get_path()))
	
	_update_pid()


func _physics_process(delta: float) -> void:
	if has_input() or is_moving():
		_movement(delta)

#endregion









#region Jump

func can_jump():
	return jump_cast.is_colliding()


func jump():
	if not has_jumped:
		rigid_body.apply_central_impulse(Vector3.UP * jump_force)
		has_jumped = true


func reset_jump():
	has_jumped = false

#endregion








func _movement(delta):
	var forward = -forward_marker.global_transform.basis.z
	var right = forward_marker.global_transform.basis.x
	
	var move_direction = (forward * input_direction.y + right * input_direction.x).normalized() * input_strength
	
	var target_velocity = (move_direction * target_speed)
	
	var velocity_error = target_velocity - rigid_body.linear_velocity
	
	var pid_output = _pid.update(velocity_error, delta)
	var total_force = pid_output * acceleration * rigid_body.mass
	
	# optional clamp to stop insane physics
	var max_f = 2000.0 * rigid_body.mass 
	total_force = total_force.limit_length(max_f)
	
	total_force.y = 0.0
	rigid_body.apply_central_force(total_force)


func has_input():
	return input_strength > 0.01


func is_stopped():
	return rigid_body.linear_velocity.length_squared() < 0.01


func is_moving():
	return rigid_body.linear_velocity.length_squared() > 0.01


func is_ground_moving(ground_velocity : Vector3):
	return ground_velocity.length_squared() > 0.01


func _find_rigid_body() -> RigidBody3D:
	if is_instance_of(self, RigidBody3D):
		return get_node(".")
	elif get_parent() is RigidBody3D:
		return get_parent()
	else:
		assert(rigid_body != null, "ERROR: No rigid_body was assigned nor could be found for TatePhysicsCharacterMotor. "+str(get_path()))
	
	return null


func _update_pid() -> void:
	_pid._p = p
	_pid._i = i
	_pid._d = d
