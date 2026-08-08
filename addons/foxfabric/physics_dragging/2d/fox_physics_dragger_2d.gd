@icon("uid://8ov6aqrt3g77")
class_name FoxPhysicsDragger2D
extends Node2D
## Manipulates a [RigidBody2D] by applying localized forces and torques
## to match this node's global position and rotation.
##
## Move this node and the grabbed body chases it. The pull is a force rather than a teleport, so
## the body still collides with the world on the way.
## [codeblock]
## @onready var dragger: FoxPhysicsDragger2D = $Dragger
##
## func _on_grab(body: RigidBody2D, at: Vector2) -> void:
##     dragger.grab(body, at, heavy_profile)
##
## func _on_release() -> void:
##     dragger.release()
## [/codeblock]
## The hit point handed to [method grab] is where the body was actually struck, and the body
## pivots around that point rather than its centre. Grabbing a plank by one end swings it like a
## plank. [member max_pull_force] caps the whole thing so a stiff profile cannot launch anything.




## Gains applied to the profile when it drives rotation rather than position.
## [br][br]
## Matched on purpose, so a profile damped sensibly for pulling is damped sensibly for turning
## too. Once [method torque_scale_for] has removed the difference in units between the two, the
## same stiffness and damping describe both, and one number does not have to be a compromise
## between them.
const TORQUE_SPRING_GAIN: float = 0.5
const TORQUE_DAMPING_GAIN: float = 0.5




#region Variables

@export_group("Default Drag Settings")

## The default strength of the pull if no profile is provided.
@export var default_stiffness: float = 800.0

## The default control of the pull if no profile is provided.
@export var default_damping: float = 25.0

## The default upright behaviour if no profile is provided.
## See [member FoxPhysicsDragProfile.keep_upright].
@export var default_keep_upright: bool = false

## The absolute maximum force this dragger can apply to a body in a single frame.
@export var max_pull_force: float = 4000.0

var _current_body: RigidBody2D
var _grab_offset_local: Vector2
var _skip_first_frame: bool = false

var _current_stiffness: float
var _current_damping: float
var _current_keep_upright: bool
var _current_torque_scale: float = 1.0

#endregion




#region Public API

## Grabs a [RigidBody2D] at a specific global hit point.
## Optionally pass a [FoxPhysicsDragProfile] to override the default stiffness and damping.
func grab(body: RigidBody2D, hit_point: Vector2, profile: FoxPhysicsDragProfile = null) -> void:
	if not is_instance_valid(body):
		push_error("FoxPhysicsDragger2D: Attempted to grab a null or invalid RigidBody2D.")
		return

	_current_body = body
	_current_stiffness = profile.stiffness if profile else default_stiffness
	_current_damping = profile.damping if profile else default_damping
	_current_keep_upright = profile.keep_upright if profile else default_keep_upright
	_current_torque_scale = torque_scale_for(body)

	# Reset the velocity of the grabbed body to stop any movement
	_current_body.linear_velocity = Vector2.ZERO
	_current_body.angular_velocity = 0.0

	# Store where we grabbed relative to center of mass
	_grab_offset_local = _current_body.to_local(hit_point)

	_skip_first_frame = true


## How much to multiply a raw torque by so [member FoxPhysicsDragProfile.stiffness] means the
## same thing for turning as it does for pulling.
## [br][br]
## A body's inertia is measured in pixels squared, so it is numerically enormous next to its
## mass: a crate of mass 30 has an inertia around 15000. Feeding the spring straight to
## [method RigidBody2D.apply_torque] therefore produces an angular acceleration near 0.03 rad/s,
## which is correct arithmetic and a motionless object. Scaling by inertia over mass, which has
## units of length squared, cancels that out and leaves angular acceleration in the same terms
## as the linear side: spring over mass.
## [br][br]
## Returns 1.0 when the body has no rotational inertia to speak of, so a locked or degenerate
## body is left alone rather than multiplied by nonsense.
static func torque_scale_for(body: RigidBody2D) -> float:
	if not is_instance_valid(body) or body.mass <= 0.0:
		return 1.0

	var state: PhysicsDirectBodyState2D = PhysicsServer2D.body_get_direct_state(body.get_rid())
	if state == null or state.inverse_inertia <= 0.0:
		return 1.0

	return (1.0 / state.inverse_inertia) / body.mass


## The rotation a held body is pulled towards, given the dragger's [param rotation].
## [br][br]
## With [param keep_upright] off the body copies the dragger's rotation. With it on the target
## is level, so the body is carried flat however the dragger is turned.
## [br][br]
## Simpler than the 3D counterpart on purpose: a 2D rotation is one angle, so there is no facing
## to preserve while the tilt is removed.
## [br][br]
## Static so the result can be checked without a body in hand.
static func target_rotation_for(rotation: float, keep_upright: bool) -> float:
	return 0.0 if keep_upright else rotation


## Releases the currently held [RigidBody2D].
## If [param dampen_spin] is [code]true[/code], it will aggressively kill residual angular velocity
## to prevent unrealistic spinning upon release.
func release(dampen_spin: bool = true) -> void:
	if not is_instance_valid(_current_body):
		push_error("FoxPhysicsDragger2D: Attempted to release a null or invalid RigidBody2D.")
		return

	if dampen_spin and absf(_current_body.angular_velocity) < 2.0:
		_current_body.angular_velocity *= 0.1

	_current_body.sleeping = false
	_current_body = null

#endregion




#region Private

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(_current_body):
		return

	if _skip_first_frame:
		_skip_first_frame = false
		return

	_apply_positional_force()
	_apply_rotational_torque()


## Applies a positional force to the grabbed RigidBody2D based on its current position and velocity.
func _apply_positional_force() -> void:
	# Where the grab point is right now in the world
	var global_offset := _current_body.global_transform.basis_xform(_grab_offset_local)
	var current_grab_point := _current_body.global_position + global_offset

	var diff_pos := global_position - current_grab_point

	# Velocity of that specific point, for accurate damping. In 2D the angular velocity is a
	# scalar, so the cross product with the offset is its perpendicular scaled by that scalar.
	var spin_at_point := _current_body.angular_velocity * Vector2(-global_offset.y, global_offset.x)
	var velocity_at_point := _current_body.linear_velocity + spin_at_point

	var force := (diff_pos * _current_stiffness) - (velocity_at_point * _current_damping)

	if force.length() > max_pull_force:
		force = force.normalized() * max_pull_force

	_current_body.apply_force(force, global_offset)


## Applies a rotational torque to the grabbed RigidBody2D based on its current orientation.
func _apply_rotational_torque() -> void:
	var target := target_rotation_for(global_rotation, _current_keep_upright)

	# Shortest signed way round, so the body never takes the long way to the same angle.
	var diff := angle_difference(_current_body.global_rotation, target)

	# Deadzone to stop micro-jitter
	if absf(rad_to_deg(diff)) < 1.0:
		var settle := -_current_body.angular_velocity * _current_damping * TORQUE_DAMPING_GAIN
		_current_body.apply_torque(settle * _current_torque_scale)
	else:
		var torque := (diff * (_current_stiffness * TORQUE_SPRING_GAIN)) \
			- (_current_body.angular_velocity * (_current_damping * TORQUE_DAMPING_GAIN))
		_current_body.apply_torque(torque * _current_torque_scale)

#endregion
