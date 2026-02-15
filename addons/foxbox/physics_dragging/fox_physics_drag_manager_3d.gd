class_name FoxPhysicsDragManager3D
extends Node3D

## Required external nodes (Dependency Injection)
@export var joint: Generic6DOFJoint3D
@export var anchor: StaticBody3D

## Default fallback settings (if grabbing a raw RigidBody)
@export_group("Default Settings")
@export var default_stiffness: float = 20.0
@export var default_damping: float = 1.0

# State
var _current_body: RigidBody3D





# ------------------------------------------------------------------------------
# Public API
# ------------------------------------------------------------------------------

## The "Smart" Grab: Uses the component's data to configure the grab
func grab_component(draggable: FoxDraggable3D) -> void:
	if not draggable or not draggable.physics_body:
		push_warning("FoxPhysicsGrabber: Invalid draggable component.")
		return
		
	_setup_grab(
		draggable.physics_body,
		draggable.stiffness,
		draggable.damping,
		draggable.keep_upright
	)

## The "Raw" Grab: Just grabs a physics object with default settings
func grab_body(body: RigidBody3D) -> void:
	if not body: return
	_setup_grab(body, default_stiffness, default_damping, false)


## Release whatever is currently held
func release() -> void:
	if _current_body:
		# 1. Disconnect Joint
		joint.node_b = NodePath()
		
		# 2. Reset Physics State
		_current_body.sleeping = false
		_current_body = null

# ------------------------------------------------------------------------------
# Internal Logic
# ------------------------------------------------------------------------------

func _setup_grab(body: RigidBody3D, stiffness: float, damping: float, keep_upright: bool) -> void:
	_current_body = body
	
	# 1. Teleport Anchor (Zero Error)
	anchor.global_transform = _current_body.global_transform
	
	# 2. Setup Linear Spring (The Pull)
	# (We enable the linear spring to pull the object to the hand)
	joint.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, false) # No hard walls
	joint.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_SPRING, true) # Yes rubber band
	joint.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, false) # No hard walls
	joint.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_SPRING, true) # Yes rubber band
	joint.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_LIMIT, false) # No hard walls
	joint.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_LINEAR_SPRING, true) # Yes rubber band
	
	joint.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_STIFFNESS, stiffness)
	joint.set_param_x(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_DAMPING, damping)
	joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_STIFFNESS, stiffness * 20)
	joint.set_param_y(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_DAMPING, damping)
	joint.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_STIFFNESS, stiffness)
	joint.set_param_z(Generic6DOFJoint3D.PARAM_LINEAR_SPRING_DAMPING, damping)
	
	joint.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
	joint.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
	joint.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, true)
	
	# (Repeat for Y and Z...)
	
	# 3. Setup Angular Spring (The Rotation Lock)
	# THIS is where keep_upright is used.
	
	if keep_upright:
		# OPTION A: "Locked" Rotation
		# We enable angular springs. The object will try to rotate to match the Anchor.
		
		var angular_stiffness := 0.0001
		var angular_damping := damping * 5
		
		joint.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, false)
		#joint.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING, true)
		joint.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, false)
		#joint.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING, true)
		joint.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_LIMIT, false)
		#joint.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING, true)

		# We generally use the same stiffness as linear, or slightly higher for a "tight" lock.
		#joint.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_STIFFNESS, angular_stiffness)
		#joint.set_param_x(Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_DAMPING, angular_damping)
		#joint.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_STIFFNESS, angular_stiffness)
		#joint.set_param_y(Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_DAMPING, angular_damping)
		#joint.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_STIFFNESS, angular_stiffness)
		#joint.set_param_z(Generic6DOFJoint3D.PARAM_ANGULAR_SPRING_DAMPING, angular_damping)
		# (Repeat for Y and Z...)
		
	else:
		# OPTION B: "Dead Fish" Rotation
		# We disable springs. The object will tumble freely while being dragged.
		
		joint.set_flag_x(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING, false)
		joint.set_flag_y(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING, false)
		joint.set_flag_z(Generic6DOFJoint3D.FLAG_ENABLE_ANGULAR_SPRING, false)
		# (Repeat for Y and Z...)
	

	# 4. Connect
	joint.node_a = anchor.get_path()
	joint.node_b = _current_body.get_path()
