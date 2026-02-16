extends Camera3D

@export var dragger_raycast : RayCast3D
@export var interaction_sensor : FoxInteractionSensor3D
@export var dragger : FoxPhysicsDragManager3D

# State
var _dragged_object : FoxDraggable3D
var is_rotating_mode: bool = false
var last_mouse_pos := Vector2.ZERO
var hold_height := 0.0 # Height offset relative to raycast hit

func _ready() -> void:
	dragger_raycast.enabled = true

func _physics_process(_delta):
	# 1. Update Raycasts
	var mouse_pos = get_viewport().get_mouse_position()
	var local_ray_dir = get_local_mouse_direction(mouse_pos)
	
	interaction_sensor.target_position = local_ray_dir * interaction_sensor.interaction_range
	dragger_raycast.target_position = local_ray_dir * 30.0
	dragger_raycast.force_raycast_update() # Critical: Ensure fresh data
	
	# 2. Update Dragger Position (Only if not rotating)
	if not is_rotating_mode:
		var target_point: Vector3
		
		if dragger_raycast.is_colliding():
			# Hit a wall? Hold it there.
			target_point = dragger_raycast.get_collision_point()
		else:
			# Hit sky? Hold it at max distance in front of us.
			target_point = dragger_raycast.to_global(dragger_raycast.target_position)
		
		# Apply Hold Height/Distance modification
		# (You can modify this logic if you want 'Trombone' sliding)
		target_point.y += hold_height
		
		# Move the dragger (The Manager handles the Anchor follow logic)
		dragger.global_position = target_point

func _process(delta: float) -> void:
	# --- INPUT HANDLING ---
	
	# 1. Rotation Mode (RMB)
	if Input.is_action_just_pressed("rmb"):
		if not is_rotating_mode:
			is_rotating_mode = true
			dragger.set_rotation_override(true) # Tell manager to lock rotation
			last_mouse_pos = get_viewport().get_mouse_position()
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
			
	elif Input.is_action_just_released("rmb"):
		if is_rotating_mode:
			is_rotating_mode = false
			dragger.set_rotation_override(false) # Release lock
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			Input.warp_mouse(last_mouse_pos * get_viewport().sdf_scale)

	# 2. Clicking / Grabbing
	if Input.is_action_just_pressed("click"):
		# Reset rotation to flat when picking up new object
		dragger.rotation = Vector3.ZERO
		
		var interactable_target = interaction_sensor.get_current_target()
		if interactable_target:
			_try_handle_target(interactable_target)

	if Input.is_action_just_released("click"):
		if _dragged_object:
			dragger.release()
			_dragged_object = null

	# 3. Zoom / Height Adjustment
	if _dragged_object:
		if Input.is_action_just_pressed("zoom_in"):
			hold_height = clamp(hold_height + 0.5, -2.0, 5.0)
		elif Input.is_action_just_pressed("zoom_out"):
			hold_height = clamp(hold_height - 0.5, -2.0, 5.0)

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if is_rotating_mode and _dragged_object:
			_handle_object_rotation(event)

func _handle_object_rotation(event: InputEventMouseMotion):
	# Rotate the Drag Point (The "Ghost Hand")
	# The Physics Joint will twist the object to catch up.
	
	# YAW (Left/Right) - Rotate around GLOBAL UP
	dragger.rotate_y(deg_to_rad(-event.relative.x * 0.1))
	
	# PITCH (Up/Down) - Rotate around CAMERA RIGHT
	var cam_right = global_transform.basis.x
	dragger.rotate(cam_right, deg_to_rad(-event.relative.y * 0.1))

func _try_handle_target(interactable: FoxInteractable3D):
	var entity = interactable.context_node as InteractionDemoEntity
	if not entity:
		interactable.interact()
		return

	var hit_point = interaction_sensor.raycast.get_collision_point()

	var drag_data = entity.get_drag_component()
	if drag_data:
		_dragged_object = drag_data
		# Pass hit_point here!
		dragger.grab_component(_dragged_object, hit_point) 
		return
		
	interactable.interact()

func get_local_mouse_direction(mouse_pos: Vector2) -> Vector3:
	var world_normal = project_ray_normal(mouse_pos)
	return global_transform.basis.inverse() * world_normal
