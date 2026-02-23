# demo player for interaction and physics dragging
extends Camera3D

@export var dragger_raycast : RayCast3D
@export var interaction_sensor : FoxInteractionRaycast3D
@export var dragger : FoxPhysicsDragger3D

# State
var _dragged_object : RigidBody3D
var is_rotating_mode: bool = false
var last_mouse_pos := Vector2.ZERO

# "Lift" Height: How high above the ground/cursor the object floats.
# Start at 0.5 so it doesn't drag/scrape along the floor immediately.
var hold_height := 0.5 


func _ready() -> void:
	dragger_raycast.enabled = true


func _physics_process(_delta):
	# 1. Update Raycasts
	var mouse_pos = get_viewport().get_mouse_position()
	var local_ray_dir = get_local_mouse_direction(mouse_pos)
	
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


func _process(delta: float) -> void:	
	# Rotation Mode (RMB)
	if Input.is_action_just_pressed("rmb"):
		is_rotating_mode = true
		last_mouse_pos = get_viewport().get_mouse_position()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			
	elif Input.is_action_just_released("rmb"):
		is_rotating_mode = false
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_viewport().warp_mouse(last_mouse_pos)

	# Click & Grab
	if Input.is_action_just_pressed("click"):
		var interactable_target = interaction_sensor.get_current_target()
		if interactable_target:
			interactable_target.interact(self)

	if Input.is_action_just_released("click"):
		if _dragged_object:
			dragger.release(true)
			_dragged_object = null

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
			_handle_object_rotation(event)


func _handle_object_rotation(event: InputEventMouseMotion):
	# Rotate the Dragger. The object will pivot around the grab point to match.
	
	# YAW: Rotate around the WORLD UP axis (Standard top-down rotation)
	dragger.rotate(Vector3.UP, deg_to_rad(-event.relative.x * 0.2))
	
	# PITCH: Rotate around CAMERA RIGHT (Tumble forward/back)
	var cam_right = global_transform.basis.x
	dragger.rotate(cam_right, deg_to_rad(-event.relative.y * 0.2))


func drag_target(body: RigidBody3D, drag_data : FoxPhysicsDragProfile):
	if drag_data:
		_dragged_object = body
		var hit_point = interaction_sensor.get_collision_point()
		
		# 1. Calculate initial Hold Height
		# This prevents the object from snapping Up or Down when grabbed.
		# If I grab a box on a table (height 2), my hold_height becomes (2 - floor_height).
		# We approximate this by just using the Y difference from the "Ground" cursor hit?
		# A simpler way: Reset hold_height to 0 relative to where we clicked, or keep it sticky.
		
		# Let's just start clean:
		# We snapped the dragger to the hit point.
		#dragger.global_position = hit_point
		
		# We set the logic to maintain that height relative to future raycasts.
		# If dragger is at Y=2, and Raycast is at Y=2, hold_height = 0.
		hold_height = 0.0 
		
		# Align Dragger rotation (Repo Feel)
		#dragger.global_basis = _dragged_object.physics_body.global_basis
		
		dragger.grab(_dragged_object, hit_point, drag_data) 
		return


func get_local_mouse_direction(mouse_pos: Vector2) -> Vector3:
	var world_normal = project_ray_normal(mouse_pos)
	return global_transform.basis.inverse() * world_normal
