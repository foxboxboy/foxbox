extends Camera3D

@export var dragger_raycast : RayCast3D
@export var interaction_sensor : FoxInteractionSensor3D
@export var dragger : FoxPhysicsDragManager3D

# State
var _dragged_object : FoxDraggable3D
var is_rotating_mode: bool = false
var last_mouse_pos := Vector2.ZERO
var current_hold_distance := 2.5 # How far away we hold the object

func _ready() -> void:
	dragger_raycast.enabled = true

func _physics_process(_delta):
	# 1. Update Interaction Sensor (Finding things)
	var mouse_pos = get_viewport().get_mouse_position()
	var local_ray_dir = get_local_mouse_direction(mouse_pos)
	interaction_sensor.target_position = local_ray_dir * interaction_sensor.interaction_range
	
	# 2. Update Dragger Position (The Floating Hand)
	if _dragged_object:
		# Calculate where the hand WANTS to be (Floating in front of camera)
		var target_pos = global_position + (local_ray_dir * current_hold_distance)
		
		# WALL CHECK: Raycast from eyes to target to prevent clipping
		# We reuse the dragger_raycast for this check
		dragger_raycast.target_position = local_ray_dir * current_hold_distance
		dragger_raycast.force_raycast_update()
		
		if dragger_raycast.is_colliding():
			# If wall is closer, pull hand back
			target_pos = dragger_raycast.get_collision_point()
			# Pull back slightly (padding)
			target_pos -= (target_pos - global_position).normalized() * 0.2
			
		# Update the Ghost Hand
		dragger.global_position = target_pos

func _process(delta: float) -> void:
	# --- INPUT HANDLING ---
	
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
			_try_handle_target(interactable_target)

	if Input.is_action_just_released("click"):
		if _dragged_object:
			dragger.release() # True = Dampen spin on release
			_dragged_object = null

	# Zoom (Distance Adjustment)
	if _dragged_object:
		if Input.is_action_just_pressed("zoom_in"):
			current_hold_distance = clamp(current_hold_distance + 0.5, 1.0, 5.0)
		elif Input.is_action_just_pressed("zoom_out"):
			current_hold_distance = clamp(current_hold_distance - 0.5, 1.0, 5.0)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if is_rotating_mode and _dragged_object:
			_handle_object_rotation(event)

func _handle_object_rotation(event: InputEventMouseMotion):
	# REPO STYLE ROTATION
	# We rotate the "Ghost Hand" (Dragger). 
	# The Physics Manager pulls the object's corner to this hand.
	# The result: The object pivots around the grab point.
	
	# YAW (Left/Right) - Rotate around GLOBAL UP
	dragger.rotate_y(deg_to_rad(-event.relative.x * 0.2))
	
	# PITCH (Up/Down) - Rotate around CAMERA RIGHT
	var cam_right = global_transform.basis.x
	dragger.rotate(cam_right, deg_to_rad(-event.relative.y * 0.2))

func _try_handle_target(interactable: FoxInteractable3D):
	var entity = interactable.context_node as InteractionDemoEntity
	if not entity:
		interactable.interact()
		return

	var drag_data = entity.get_drag_component()
	if drag_data:
		_dragged_object = drag_data
		var hit_point = interaction_sensor.raycast.get_collision_point()
		
		# --- CRITICAL SETUP ---
		# 1. Calculate how far away the object is so we don't snap it to our face.
		current_hold_distance = global_position.distance_to(hit_point)
		
		# 2. Teleport Dragger to the EXACT grab point
		dragger.global_position = hit_point
		
		# 3. Align Dragger rotation to the Object.
		# This prevents the object from snapping "Upright" when we grab it.
		# It keeps its chaotic, natural rotation.
		dragger.global_basis = _dragged_object.physics_body.global_basis
		
		dragger.grab_component(_dragged_object, hit_point) 
		return
		
	interactable.interact()

func get_local_mouse_direction(mouse_pos: Vector2) -> Vector3:
	var world_normal = project_ray_normal(mouse_pos)
	return global_transform.basis.inverse() * world_normal
