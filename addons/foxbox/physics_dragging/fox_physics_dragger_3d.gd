class_name FoxPhysicsDragger3D
extends FoxNode3D
## Manipulates a [RigidBody3D] by applying localized forces and torques 
## to match this node's global position and rotation. 





#region Variables

@export_group("Default Drag Settings")

## The default strength of the pull if no profile is provided.
@export var default_stiffness: float = 800.0 

## The default control of the pull if no profile is provided.
@export var default_damping: float = 25.0 

## The absolute maximum force this dragger can apply to a body in a single frame.
@export var max_pull_force: float = 4000.0

var _current_body: RigidBody3D
var _grab_offset_local: Vector3
var _skip_first_frame: bool = false

var _current_stiffness: float
var _current_damping: float

#endregion





#region Public API

## Grabs a [RigidBody3D] at a specific global hit point. 
## Optionally pass a [FoxPhysicsDragProfile] to override the default stiffness and damping.
func grab(body: RigidBody3D, hit_point: Vector3, profile: FoxPhysicsDragProfile = null) -> void:
	if not is_instance_valid(body):
		push_error("FoxPhysicsDragger3D: Attempted to grab a null or invalid RigidBody3D.")
		return
		
	_current_body = body
	_current_stiffness = profile.stiffness if profile else default_stiffness
	_current_damping = profile.damping if profile else default_damping
	
	# 1. Kill Momentum (Stop the fight before it starts)
	_current_body.linear_velocity = Vector3.ZERO
	_current_body.angular_velocity = Vector3.ZERO
	
	# 2. Store the "Knot" (Where we grabbed relative to center of mass)
	_grab_offset_local = _current_body.to_local(hit_point)
	
	_skip_first_frame = true


## Releases the currently held [RigidBody3D].
## If [param dampen_spin] is [code]true[/code], it will aggressively kill residual angular velocity 
## to prevent unrealistic spinning upon release.
func release(dampen_spin: bool = true) -> void:
	if is_instance_valid(_current_body):
		# Smart Release: If it's just vibrating, kill the spin. If throwing, keep it.
		if dampen_spin and _current_body.angular_velocity.length() < 2.0:
			_current_body.angular_velocity *= 0.1
			
		_current_body.sleeping = false
		_current_body = null

#endregion





#region Private Logic

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_current_body):
		return

	if _skip_first_frame:
		_skip_first_frame = false
		return

	_apply_positional_force()
	_apply_rotational_torque()


func _apply_positional_force() -> void:
	# Calculate where the Grab Point is right now in the world
	var global_offset = _current_body.global_basis * _grab_offset_local
	var current_grab_point = _current_body.global_position + global_offset
	
	var diff_pos = global_position - current_grab_point
	
	# Calculate Velocity of that specific point for accurate damping
	var vel_at_point = _current_body.linear_velocity + _current_body.angular_velocity.cross(global_offset)
	
	var force = (diff_pos * _current_stiffness) - (vel_at_point * _current_damping)
	
	if force.length() > max_pull_force:
		force = force.normalized() * max_pull_force
		
	_current_body.apply_force(force, global_offset)


func _apply_rotational_torque() -> void:
	var target_basis = global_transform.basis
	var current_basis = _current_body.global_transform.basis
	
	var diff = (target_basis * current_basis.inverse()).get_rotation_quaternion()
	var axis = diff.get_axis().normalized()
	var angle = diff.get_angle()
	
	if angle > PI: 
		angle -= TAU
	
	# Deadzone (Stop micro-jitter)
	if abs(rad_to_deg(angle)) < 1.0:
		_current_body.apply_torque(-_current_body.angular_velocity * _current_damping * 0.1)
	else:
		var torque = (axis * angle * (_current_stiffness * 0.5)) - (_current_body.angular_velocity * (_current_damping * 0.2))
		_current_body.apply_torque(torque)

#endregion
