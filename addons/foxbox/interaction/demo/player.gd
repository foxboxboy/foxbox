extends Camera3D

@export var dragger_raycast : RayCast3D
@export var interaction_sensor : FoxInteractionSensor3D
@export var dragger : FoxPhysicsDragManager3D

var _dragged_object : FoxDraggable3D

var is_rotating_mode: bool = false

var last_mouse_pos := Vector2.ZERO

var hold_height := 2.0

func _ready() -> void:
	dragger_raycast.enabled = true


func _physics_process(_delta):
	var mouse_pos = get_viewport().get_mouse_position()
	var local_ray_dir = get_local_mouse_direction(mouse_pos)
	
	interaction_sensor.target_position = local_ray_dir * interaction_sensor.interaction_range
	
	dragger_raycast.target_position = local_ray_dir * 30.0
	
	if not is_rotating_mode:
		await get_tree().physics_frame
		dragger.global_position = dragger_raycast.get_collision_point()
		dragger.global_position.y += hold_height


func _process(delta: float) -> void:
	if Input.is_action_pressed("rmb") and not is_rotating_mode:
		is_rotating_mode = true
		last_mouse_pos = get_viewport().get_mouse_position()
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	elif not Input.is_action_pressed("rmb") and is_rotating_mode:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		Input.warp_mouse(last_mouse_pos * get_viewport().get_stretch_transform())
		is_rotating_mode = false
	
	if Input.is_action_just_pressed("click"):
		dragger.rotation = Vector3(0,0,0)

		var interactable_target = interaction_sensor.get_current_target()
		
		if interactable_target:
			_try_handle_target(interactable_target)

	if Input.is_action_just_released("click"):
		if _dragged_object:
			dragger.release()
			_dragged_object = null

	
	if _dragged_object:
		if Input.is_action_just_pressed("zoom_in"):
			hold_height = clamp(hold_height + 0.5, 0.0, 5.0)
		elif Input.is_action_just_pressed("zoom_out"):
			hold_height = clamp(hold_height - 0.5, 0.0, 5.0)


func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if is_rotating_mode and _dragged_object:
			_handle_object_rotation(event)


func _handle_object_rotation(event: InputEventMouseMotion):
	# Rotate the Drag Point (The "Ghost Hand"), NOT the object directly.
	# The Physics Joint will twist the object to catch up.
	
	# YAW (Left/Right) - Rotate around GLOBAL UP (Standard turret feel)
	dragger.rotate_y(deg_to_rad(event.relative.x * 0.1))
	
	# PITCH (Up/Down) - Rotate around CAMERA RIGHT (Tumble feel)
	# We use the camera's basis so "Up" is always "Up on screen"
	var cam_right = global_transform.basis.x
	dragger.rotate(cam_right, deg_to_rad(event.relative.y * 0.1))


func _try_handle_target(interactable: FoxInteractable3D):
	var entity = interactable.context_node as InteractionDemoEntity
	if not entity:
		interactable.interact()
		return

	var drag_data = entity.get_drag_component()
	if drag_data:
		_dragged_object = drag_data
		dragger.grab_component(_dragged_object)
		return 
		
	interactable.interact()


func get_local_mouse_direction(mouse_pos: Vector2) -> Vector3:
	var world_normal = project_ray_normal(mouse_pos)
	return global_transform.basis.inverse() * world_normal
