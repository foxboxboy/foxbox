class_name FoxPhysicsDragManager3D
extends Node3D

@export_group("Default Settings")
@export var default_stiffness: float = 20.0
@export var default_damping: float = 1.0

var _current_body: RigidBody3D
var _current_settings: Dictionary = {} 
var _rotation_override: bool = false 
var _grab_offset_local: Vector3 = Vector3.ZERO

# NEW: A safety flag to prevent "Ghost Velocity" explosions
var _skip_first_frame: bool = false 

# ------------------------------------------------------------------------------
# Public API
# ------------------------------------------------------------------------------

func grab_component(draggable: FoxDraggable3D, hit_point: Vector3) -> void:
	if not draggable or not draggable.physics_body: return
	
	_current_settings = {
		"stiffness": draggable.stiffness,
		"damping": draggable.damping,
		"keep_upright": draggable.keep_upright
	}
	_setup_grab(draggable.physics_body, hit_point)

func grab_body(body: RigidBody3D, hit_point: Vector3) -> void:
	if not body: return
	_current_settings = {
		"stiffness": default_stiffness,
		"damping": default_damping,
		"keep_upright": false 
	}
	_setup_grab(body, hit_point)

func release() -> void:
	if _current_body:
		_current_body.angular_velocity *= 0.25
		_current_body.sleeping = false
		_current_body = null
		_current_settings = {}
		_rotation_override = false

func set_rotation_override(active: bool) -> void:
	_rotation_override = active

# ------------------------------------------------------------------------------
# Internal Logic
# ------------------------------------------------------------------------------

func _setup_grab(body: RigidBody3D, hit_point: Vector3) -> void:
	_current_body = body
	
	# 1. KILL MOMENTUM
	_current_body.linear_velocity = Vector3.ZERO
	_current_body.angular_velocity = Vector3.ZERO
	
	# 2. Setup Offset
	_grab_offset_local = _current_body.to_local(hit_point)
	global_basis = _current_body.global_basis
	
	# 3. ENABLE SAFETY FLAG (The Fix)
	# We refuse to run physics math this frame. We wait for the velocity reset to take effect.
	_skip_first_frame = true

func _physics_process(delta):
	if not _current_body:
		return

	# SAFETY CHECK
	if _skip_first_frame:
		_skip_first_frame = false
		return # Exit immediately. Do not pass Go. Do not apply Forces.

	# --- 1. DETERMINE OFFSET ---
	var effective_offset_local = _grab_offset_local
	if _rotation_override:
		effective_offset_local = Vector3.ZERO

	# --- 2. LINEAR SPRING ---
	var target_pos = global_position
	
	var global_offset = _current_body.global_basis * effective_offset_local
	var current_grab_point = _current_body.global_position + global_offset
	var diff_pos = target_pos - current_grab_point
	
	var kp = _current_settings.get("stiffness", 20.0)
	var kd = _current_settings.get("damping", 1.0)
	
	var velocity_at_point = _current_body.linear_velocity + _current_body.angular_velocity.cross(global_offset)
	
	var spring_force = (diff_pos * kp) - (velocity_at_point * kd)
	
	_current_body.apply_force(spring_force, global_offset)

	# --- 3. ANGULAR SPRING ---
	var should_rotate = _current_settings.get("keep_upright", false) or _rotation_override
	
	if should_rotate:
		var target_basis = global_transform.basis
		var current_basis = _current_body.global_transform.basis
		
		var diff = (target_basis * current_basis.inverse()).get_rotation_quaternion()
		var axis = diff.get_axis().normalized()
		var angle = diff.get_angle()
		
		if angle > PI: angle -= TAU 
		
		var r_kp = kp * 8.0
		var r_kd = kd * 4.0
		
		if _rotation_override:
			r_kp = 200.0
			r_kd = 25.0
			
		var spring_torque = (axis * angle * r_kp) - (_current_body.angular_velocity * r_kd)
		
		if spring_torque.length() > 50.0:
			spring_torque = spring_torque.normalized() * 50.0
			
		_current_body.apply_torque(spring_torque)

	else:
		_current_body.apply_torque(_current_body.angular_velocity * -0.1)
