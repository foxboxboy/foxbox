class_name FoxPhysicsDragManager3D
extends Node3D

@export_group("Settings")
@export var stiffness: float = 800.0  # Strength of the hold
@export var damping: float = 25.0     # Smoothness (Resistance)

var _current_body: RigidBody3D
var _grab_offset_local: Vector3
var _skip_first_frame: bool = false

# ------------------------------------------------------------------------------
# Public API
# ------------------------------------------------------------------------------

# This is the function your PlayerController was missing!
func grab_component(draggable: FoxDraggable3D, hit_point: Vector3) -> void:
	if not draggable or not draggable.physics_body: return
	
	# Allow individual objects to override stiffness (e.g. heavy pianos)
	var obj_stiffness = draggable.stiffness if draggable.stiffness > 0 else stiffness
	var obj_damping = draggable.damping if draggable.damping > 0 else damping
	
	_setup_grab(draggable.physics_body, hit_point, obj_stiffness, obj_damping)

func grab_body(body: RigidBody3D, hit_point: Vector3) -> void:
	if not body: return
	_setup_grab(body, hit_point, stiffness, damping)

func release(dampen_spin: bool = true) -> void:
	if _current_body:
		# Smart Release: If it's just vibrating, kill the spin. If throwing, keep it.
		if dampen_spin and _current_body.angular_velocity.length() < 2.0:
			_current_body.angular_velocity *= 0.1
			
		_current_body.sleeping = false
		_current_body = null

# ------------------------------------------------------------------------------
# Internal Logic
# ------------------------------------------------------------------------------

func _setup_grab(body: RigidBody3D, hit_point: Vector3, k: float, d: float) -> void:
	_current_body = body
	stiffness = k
	damping = d
	
	# 1. Kill Momentum (Stop the fight before it starts)
	_current_body.linear_velocity = Vector3.ZERO
	_current_body.angular_velocity = Vector3.ZERO
	
	# 2. Store the "Knot" (Where we grabbed relative to center)
	_grab_offset_local = _current_body.to_local(hit_point)
	
	_skip_first_frame = true

func _physics_process(delta):
	if not _current_body:
		return

	if _skip_first_frame:
		_skip_first_frame = false
		return

	# --- 1. PIVOT DRAGGING (The R.E.P.O. Feel) ---
	# We pull the "Grab Offset" to the "Dragger Position".
	# If we rotate the Dragger, the object rotates around this point.
	
	var target_pos = global_position
	
	# Calculate where the Grab Point is right now in the world
	var global_offset = _current_body.global_basis * _grab_offset_local
	var current_grab_point = _current_body.global_position + global_offset
	
	var diff_pos = target_pos - current_grab_point
	
	# Calculate Velocity of that specific point for accurate damping
	var vel_at_point = _current_body.linear_velocity + _current_body.angular_velocity.cross(global_offset)
	
	var force = (diff_pos * stiffness) - (vel_at_point * damping)
	
	# Force Clamp (Weight): Heavy objects won't lift if force > max
	# Pianos need ~5000 force to lift. If we clamp at 4000, they drag but don't fly.
	var max_force = 4000.0 
	if force.length() > max_force:
		force = force.normalized() * max_force
		
	_current_body.apply_force(force, global_offset)

	# --- 2. ROTATION LOCK ---
	# We align the Body's rotation to the Dragger's rotation.
	# Since the PlayerController rotates the Dragger, this handles everything.
	
	var target_basis = global_transform.basis
	var current_basis = _current_body.global_transform.basis
	
	var diff = (target_basis * current_basis.inverse()).get_rotation_quaternion()
	var axis = diff.get_axis().normalized()
	var angle = diff.get_angle()
	if angle > PI: angle -= TAU
	
	# Deadzone (Stop micro-jitter)
	if abs(rad_to_deg(angle)) < 1.0:
		_current_body.apply_torque(-_current_body.angular_velocity * damping * 0.1)
	else:
		var torque = (axis * angle * (stiffness * 0.5)) - (_current_body.angular_velocity * (damping * 0.2))
		_current_body.apply_torque(torque)
