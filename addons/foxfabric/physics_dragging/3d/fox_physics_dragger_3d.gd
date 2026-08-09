@icon("uid://dqng8xj2sfcq2")
class_name FoxPhysicsDragger3D
extends FoxNode3D
## A 3D node that drags a [RigidBody3D] to its own position and rotation using forces.
##
## [FoxPhysicsDragger3D] pulls its grabbed body toward itself as it moves. The pull is a force rather than a teleport, so
## the body still collides with the world on the way.
## [codeblock]
## @onready var dragger: FoxPhysicsDragger3D = $Camera3D/Dragger
##
## func _on_grab(hit: Dictionary) -> void:
##     dragger.grab(hit.collider, hit.position, heavy_profile)
##
## func _on_release() -> void:
##     dragger.release()
## [/codeblock]
## The hit point handed to [method grab] is where the body was actually struck, and the body
## pivots around that point rather than its centre. Grabbing a plank by one end swings it like a
## plank. [member max_pull_force] caps the whole thing so a stiff profile cannot launch anything.




#region Variables

## The lead a dragger starts with, a quarter turn.
const DEFAULT_ROTATION_LEAD: float = PI / 2.0

@export_group("Default Drag Settings")

## How far this node's orientation may get ahead of what it is holding.
## [br][br]
## The torque always takes the shortest way round to its target. Turn this node more than half a
## turn ahead of the body and the shortest way becomes backwards, so the body unwinds against the
## drag instead of following it. A quarter turn leaves room to lag behind without ever crossing
## over, and anything at or above [code]PI[/code] gives that crossing back.
@export_range(0.0, 180.0, 1.0, "radians_as_degrees") var max_rotation_lead: float = DEFAULT_ROTATION_LEAD

## The default strength of the pull if no profile is provided.
@export var default_stiffness: float = 800.0

## The default control of the pull if no profile is provided.
@export var default_damping: float = 25.0

## The default upright behaviour if no profile is provided.
## See [member FoxPhysicsDragProfile.keep_upright].
@export var default_keep_upright: bool = false

## The absolute maximum force this dragger can apply to a body in a single frame.
@export var max_pull_force: float = 4000.0

var _current_body: RigidBody3D
var _grab_offset_local: Vector3
var _skip_first_frame: bool = false

var _current_stiffness: float
var _current_damping: float
var _current_keep_upright: bool

#endregion




#region Public API

## Grabs a [RigidBody3D] at a specific global hit point.
## Optionally pass a [FoxPhysicsDragProfile] to override the default stiffness and damping.
func grab(body: RigidBody3D, hit_point: Vector3, profile: FoxPhysicsDragProfile = null) -> void:
	# Check if the provided body is valid
	if not is_instance_valid(body):
		push_error("FoxPhysicsDragger3D: Attempted to grab a null or invalid RigidBody3D.")
		return

	_current_body = body
	_current_stiffness = profile.stiffness if profile else default_stiffness
	_current_damping = profile.damping if profile else default_damping
	_current_keep_upright = profile.keep_upright if profile else default_keep_upright

	# Reset the velocity of the grabbed body to stop any movement
	_current_body.linear_velocity = Vector3.ZERO
	_current_body.angular_velocity = Vector3.ZERO

	# Store where we grabbed relative to center of mass
	_grab_offset_local = _current_body.to_local(hit_point)

	_skip_first_frame = true


## The point on the held body that is being pulled, in global space.
## [br][br]
## Follows the body as it moves and turns, since it is a fixed spot on the body rather than a
## spot in the world. Useful for drawing where a grab landed, or spawning something there.
## [codeblock]
## if dragger.is_holding():
##     $GrabMarker.global_position = dragger.get_grab_point()
## [/codeblock]
## Returns the dragger's own position when nothing is held, so a marker parked on it does not
## jump to the origin between grabs.
func get_grab_point() -> Vector3:
	if not is_instance_valid(_current_body):
		return global_position

	return _current_body.to_global(_grab_offset_local)


## Whether a body is currently being dragged.
func is_holding() -> bool:
	return is_instance_valid(_current_body)


## The orientation a held body is pulled towards, given the dragger's [param basis].
## [br][br]
## With [param keep_upright] off this is the dragger's own basis, so the body copies it exactly.
## With it on, the facing is flattened onto the horizon: the body still yaws to follow the
## dragger but never tips, which is what stops a camera mounted dragger from pitching whatever
## it is carrying every time you look up or down.
## [br][br]
## Static so the result can be checked without a body in hand.
static func target_basis_for(basis: Basis, keep_upright: bool) -> Basis:
	if not keep_upright:
		return basis

	var forward := -basis.z
	forward.y = 0.0

	# Pointing straight up or down leaves nothing to flatten. The dragger's own up axis lies on
	# the horizon in exactly that case, so it carries the yaw instead.
	if forward.length_squared() < 0.0001:
		forward = basis.y
		forward.y = 0.0

	# An orthonormal basis cannot have two vertical axes, so this is unreachable in practice.
	# Bailing out beats handing a zero vector to looking_at.
	if forward.length_squared() < 0.0001:
		return basis

	return Basis.looking_at(forward, Vector3.UP)


## Releases the currently held [RigidBody3D].
## If [param dampen_spin] is [code]true[/code], it will aggressively kill residual angular velocity
## to prevent unrealistic spinning upon release.
func release(dampen_spin: bool = true) -> void:
	# Check if the current body is valid
	if not is_instance_valid(_current_body):
		push_error("FoxPhysicsDragger3D: Attempted to release a null or invalid RigidBody3D.")
		return

	# Dampen angular velocity if required and within threshold
	if dampen_spin and _current_body.angular_velocity.length() < 2.0:
		_current_body.angular_velocity *= 0.1

	# Wake up the body and reset the current body reference
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

	_rein_in_rotation()
	_apply_positional_force()
	_apply_rotational_torque()


## Pulls this node's orientation back to within [member max_rotation_lead] of the body, so
## turning it faster than the body can follow saturates rather than reversing.
## [br][br]
## With [member default_keep_upright] the target is level rather than this node's orientation, so
## there is nothing to run ahead of.
func _rein_in_rotation() -> void:
	if _current_keep_upright:
		return

	var held: Basis = _current_body.global_transform.basis.orthonormalized()
	var lead: Quaternion = (global_transform.basis.orthonormalized() * held.inverse()).get_rotation_quaternion()

	var angle: float = lead.get_angle()
	if angle > PI:
		angle -= TAU

	if absf(angle) <= max_rotation_lead:
		return

	# Through global_rotation rather than the basis, which would take this node's scale with it.
	var reined: Basis = held * Basis(lead.get_axis().normalized(), clampf(angle, -max_rotation_lead, max_rotation_lead))
	global_rotation = reined.get_euler()


## Applies a positional force to the grabbed RigidBody3D based on its current position and velocity.
func _apply_positional_force() -> void:
	# Calculate where the grab point is right now in the world
	var global_offset = _current_body.global_basis * _grab_offset_local
	var current_grab_point = _current_body.global_position + global_offset

	var diff_pos = global_position - current_grab_point

	# Calculate velocity of that specific point for accurate damping
	var velocity_at_point = _current_body.linear_velocity + _current_body.angular_velocity.cross(global_offset)

	var force = (diff_pos * _current_stiffness) - (velocity_at_point * _current_damping)

	if force.length() > max_pull_force:
		force = force.normalized() * max_pull_force

	_current_body.apply_force(force, global_offset)


## Applies a rotational torque to the grabbed RigidBody3D based on its current orientation.
func _apply_rotational_torque() -> void:
	var target_basis = target_basis_for(global_transform.basis, _current_keep_upright)
	var current_basis = _current_body.global_transform.basis

	var diff = (target_basis * current_basis.inverse()).get_rotation_quaternion()
	var axis = diff.get_axis().normalized()
	var angle = diff.get_angle()

	if angle > PI:
		angle -= TAU

	# Deadzone to stop micro-jitter
	if abs(rad_to_deg(angle)) < 1.0:
		_current_body.apply_torque(-_current_body.angular_velocity * _current_damping * 0.1)
	else:
		var torque = (axis * angle * (_current_stiffness * 0.5)) - (_current_body.angular_velocity * (_current_damping * 0.2))
		_current_body.apply_torque(torque)

#endregion
