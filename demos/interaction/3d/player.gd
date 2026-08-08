# demo player for interaction and physics dragging
extends Camera3D

## How far ahead of the held object the commanded orientation may get, in radians.
## A quarter turn. See _rein_in_spin.
const MAX_SPIN_LEAD : float = PI / 2.0

@export var dragger_raycast : RayCast3D
@export var interaction_sensor : FoxInteractionRayCast3D
@export var dragger : FoxPhysicsDragger3D

# State
var _dragged_object : RigidBody3D
var is_rotating_mode: bool = false
var last_mouse_pos : Vector2 = Vector2.ZERO

# "Lift" Height: How high above the ground/cursor the object floats.
# Start at 0.5 so it doesn't drag/scrape along the floor immediately.
var hold_height : float = 0.5 


func _ready() -> void:
	dragger_raycast.enabled = true


func _physics_process(_delta : float) -> void:
	# 1. Update Raycasts
	var mouse_pos : Vector2 = get_viewport().get_mouse_position()
	var local_ray_dir : Vector3 = get_local_mouse_direction(mouse_pos)
	
	interaction_sensor.target_position = local_ray_dir * interaction_sensor.interaction_range
	
	# Cast far into the world (e.g. 100 meters) to find the "Cursor Position"
	dragger_raycast.target_position = local_ray_dir * 100.0
	dragger_raycast.force_raycast_update()
	
	# 2. Update Dragger Position (The "God Hand")
	#if _dragged_object and not is_rotating_mode:
	if not is_rotating_mode:
		var target_point: Vector3
		
		if dragger_raycast.is_colliding():
			# HIT: Move the hand to exactly where the mouse clicked on the world (Floor/Table)
			target_point = dragger_raycast.get_collision_point()
		else:
			# MISS: If pointing at the sky, just hold it out at max range
			target_point = dragger_raycast.to_global(dragger_raycast.target_position)
		
		# Apply the "Levitation" height
		# This is CRITICAL for top-down. It lets you lift things over fences.
		target_point.y += hold_height
		
		# Teleport the ghost hand there. The physics manager will pull the object to it.
		dragger.global_position = target_point


func _process(_delta: float) -> void:
	# Rotation Mode (RMB)
	if Input.is_action_just_pressed("rmb"):
		is_rotating_mode = true
		last_mouse_pos = get_viewport().get_mouse_position()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			
	elif Input.is_action_just_released("rmb"):
		is_rotating_mode = false
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_viewport().warp_mouse(last_mouse_pos)

	# Click to pick up, click again to put down, rather than holding the button the whole time.
	# Ending the mouse capture at the end of a rotate makes the window manager report the click
	# as released, and while holding meant held that silently dropped whatever was being turned
	# the instant you stopped turning it. A toggle cannot be undone by an event nobody sent.
	if Input.is_action_just_pressed("click"):
		if _dragged_object:
			dragger.release(true)
			_dragged_object = null
		else:
			var interactable_target : FoxInteractableArea3D = interaction_sensor.get_current_target()
			if interactable_target:
				interactable_target.interact(self)

	# Height Adjustment (Mouse Wheel = Lift/Lower)
	if _dragged_object:
		if Input.is_action_just_pressed("zoom_in"):
			# Lift the object HIGHER
			hold_height = clamp(hold_height + 0.5, 0.0, 5.0)
		elif Input.is_action_just_pressed("zoom_out"):
			# Lower the object (Drop it)
			hold_height = clamp(hold_height - 0.5, 0.0, 5.0)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if is_rotating_mode and _dragged_object:
			_handle_object_rotation(event as InputEventMouseMotion)


func _handle_object_rotation(event: InputEventMouseMotion) -> void:
	# Rotate the Dragger. The object will pivot around the grab point to match.

	# YAW: Rotate around the WORLD UP axis (Standard top-down rotation)
	dragger.rotate(Vector3.UP, deg_to_rad(-event.relative.x * 0.2))

	# PITCH: Rotate around CAMERA RIGHT (Tumble forward/back)
	var cam_right : Vector3 = global_transform.basis.x
	dragger.rotate(cam_right, deg_to_rad(-event.relative.y * 0.2))

	_rein_in_spin()


## Never let the commanded orientation get more than a quarter turn from the object's own.
## [br][br]
## The dragger turns as fast as the mouse moves, but the object has to be hauled round by a
## spring and lags behind. The torque takes the shortest way to its target, so once that gap
## passes half a turn the shortest way is backwards: the object stops following and unwinds
## against the direction being dragged, while the mouse has not changed direction at all.
func _rein_in_spin() -> void:
	if not is_instance_valid(_dragged_object):
		return

	var held : Basis = _dragged_object.global_transform.basis.orthonormalized()
	var lead : Quaternion = (dragger.global_transform.basis.orthonormalized() * held.inverse()).get_rotation_quaternion()

	var angle : float = lead.get_angle()
	if angle > PI:
		angle -= TAU

	if absf(angle) <= MAX_SPIN_LEAD:
		return

	var reined : Transform3D = dragger.global_transform
	reined.basis = held * Basis(lead.get_axis().normalized(), clampf(angle, -MAX_SPIN_LEAD, MAX_SPIN_LEAD))
	dragger.global_transform = reined


func drag_target(body: RigidBody3D, drag_data : FoxPhysicsDragProfile) -> void:
	if drag_data:
		_dragged_object = body
		var hit_point : Vector3 = interaction_sensor.get_collision_point()
		
		hold_height = 0.0 
		
		dragger.grab(_dragged_object, hit_point, drag_data) 
		return


func get_local_mouse_direction(mouse_pos: Vector2) -> Vector3:
	var world_normal : Vector3 = project_ray_normal(mouse_pos)
	return global_transform.basis.inverse() * world_normal
