extends TateNode3D
class_name TateCharacter
# A big bowl of spaghetti...

@export_group("Components")
@export var physics_body : CharacterBody3D
@export var motor: TateAdvancedCharacterMotor3D
@export var visuals_pivot : Node3D
@export var character_model : TateCharacterModel
@export var camera_pivot : TateCharacterCameraPivot
@export var view_model_container : SubViewportContainer
@export var character_animator : TateCharacterAnimator

@export_group("Visuals Interpolation")
@export var max_head_pitch := 89.0


@export_group("Visual Optimizer")
## @experimental
@export var visual_optimizer : TateVisualOptimizer





var _aim_target_pitch : float
var _max_head_pitch_rad : float
var _free_look_offset: float = 0.0

var is_free_looking := false

var input_direction := Vector2.ZERO:
	set = set_input


var input_strength := 0.0:
	set(new_value):
		input_strength = clampf(new_value, 0.0, 1.0)
		motor.input_strength = new_value









#region Ready & Process

func _ready() -> void:
	assert(motor != null, "ERROR: No motor was assigned to character. "+str(get_path()))
	
	_max_head_pitch_rad = deg_to_rad(max_head_pitch)
	
	if character_animator:
		if not character_animator.character:
			character_animator.character = self


func _process(_delta: float) -> void:
	if visual_optimizer:
		if visual_optimizer.is_far:
			return
	
	character_animator.update_visuals()
	_update_freecam()

#endregion





#region Multiplayer

func set_network_role(is_authority: bool) -> void:
	## SERVER
	if is_authority:
		# turn on physics & logic
		motor.process_mode = Node.PROCESS_MODE_INHERIT
		motor.jump_cast.enabled = true
		set_physics_process(true)
		

	## CLIENT
	else:
		motor.process_mode = Node.PROCESS_MODE_DISABLED
		motor.jump_cast.enabled = false
		set_physics_process(false)

#endregion







#region Camera & ViewModel


func _update_freecam() -> void:
	if not is_free_looking and camera_pivot and _free_look_offset != 0.0:
		_free_look_offset = 0.0
		camera_pivot.rotation.y = _free_look_offset


func get_first_person_camera_pivot() -> Marker3D:
	if camera_pivot:
		return camera_pivot.first_person_camera_pivot
	return null


func get_shoulder_camera_pivot() -> Marker3D:
	if camera_pivot:
		return camera_pivot.shoulder_camera_pivot
	return null


func show_view_model() -> void:
	if view_model_container:
		view_model_container.show()


func hide_view_model() -> void:
	if view_model_container:
		view_model_container.hide()


func show_character_model() -> void:
	if character_model:
		character_model.show_meshes()


func hide_character_model() -> void:
	if character_model:
		character_model.hide_meshes()

#endregion





#region Main Input

func set_input(direction : Vector2) -> void:
	var new_value_normalized := direction.normalized()
	motor.input_direction = new_value_normalized
	input_direction = new_value_normalized


func rotate_head_relative(relative: Vector2) -> void:
	_process_pitch(relative.y)
	_process_yaw(relative.x)


func try_to_jump() -> void:
	if motor.can_jump():
		motor.jump()


func reset_jump() -> void:
	motor.reset_jump()


#endregion






#region Rotation

func _process_pitch(relative_y: float) -> void:
	_aim_target_pitch = clamp(_aim_target_pitch - relative_y, -_max_head_pitch_rad, _max_head_pitch_rad)

	if camera_pivot:
		camera_pivot.rotation.x = _aim_target_pitch


func _process_yaw(relative_x: float) -> void:
	if is_free_looking:
		_free_look_offset += -relative_x
		
		if camera_pivot:
			camera_pivot.rotation.y = _free_look_offset
			
	else:
		self.rotate_y(-relative_x)

#endregion







#region Helpers

func is_moving() -> bool:
	return physics_body.velocity.length() > 0.01


func get_aim_torso_angle_difference() -> float:
	var angle := visuals_pivot.global_rotation.y - self.global_rotation.y
	# Between -180 and +180
	angle = wrapf(angle, -PI, PI) 
	angle = angle
	return(angle)


func has_move_input() -> bool:
	return input_direction.x != 0 or input_direction.y != 0

#endregion
