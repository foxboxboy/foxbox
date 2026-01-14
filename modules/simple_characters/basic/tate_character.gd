extends TateNode3D
class_name TateCharacter
# A big bowl of spaghetti...
##  

## WARNING remove or refactor this later this is pretty stupid
@export var character_model : TateCharacterModel

@export_group("Components")
@export var aim_pivot: Marker3D
@export var torso : Node3D
@export var motor: TateAdvancedCharacterMotor3D
@export var body : CharacterBody3D
@export var forward_marker : Marker3D
@export var hands: Marker3D

@export_group("Camera Markers")
@export var shoulder_camera_marker : Marker3D
@export var first_person_camera_marker : Node3D
@export var camera_pivot : Marker3D

@export_group("Rotation")
@export var max_head_pitch := 89.0
@export var torso_sync_speed := 0.02
@export var torso_lean_into_turn_amount := PI/4



@export_group("Visual Optimizer")

@export var visual_optimizer : TateVisualOptimizer





var _aim_target_pitch : float
var _aim_target_yaw : float

var input_direction := Vector2.ZERO:
	set(new_value):
		var new_value_normalized := new_value.normalized()
		motor.input_direction = new_value_normalized
		
		rotate_aim()
		
		input_direction = new_value_normalized

var input_strength := 0.0:
	set(new_value):
		input_strength = clampf(new_value, 0.0, 1.0)
		motor.input_strength = new_value









#region Ready & Process

func _ready() -> void:
	assert(motor != null, "ERROR: No motor was assigned to character. "+str(get_path()))


func _process(_delta: float) -> void:
	if visual_optimizer:
		if visual_optimizer.is_far:
			return
	

	forward_marker.global_rotation.y = aim_pivot.global_rotation.y
	
	hands.global_rotation.x = aim_pivot.global_rotation.x
	
	sync_torso_rotation_to_aim()

#endregion





#region Multiplayer

func set_network_role(is_authority: bool):
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







#region Main Input

func rotate_head_relative(relative: Vector2) -> void:
	_aim_target_pitch = _get_aim_pitch(relative)
	_aim_target_yaw = _get_aim_yaw(relative)
	
	if camera_pivot:
		rotate_camera_pivot()
	
	rotate_aim()


func try_to_jump() -> void:
	if motor.can_jump():
		motor.jump()


func reset_jump() -> void:
	motor.reset_jump()


#endregion







#region Rotation

func rotate_camera_pivot():
	var yaw_basis := Basis(Vector3.UP, _aim_target_yaw + deg_to_rad(180))
	var pitch_basis = Basis(Vector3.LEFT, _aim_target_pitch)
	camera_pivot.basis = yaw_basis * pitch_basis


func rotate_aim():
	if Input.is_action_pressed("free_cam"):
		return
	
	var yaw_basis := Basis(Vector3.UP, _aim_target_yaw + deg_to_rad(180))
	var pitch_basis = Basis(Vector3.LEFT, _aim_target_pitch)
	aim_pivot.basis = yaw_basis * pitch_basis


func sync_torso_rotation_to_aim():
	var strafe_amount := -motor.input_direction.x * torso_lean_into_turn_amount
	var target_angle := aim_pivot.rotation.y + strafe_amount
	
	var rotation_speed : float = clamp(body.velocity.length() * torso_sync_speed, 0.1, 0.9)
	torso.rotation.y = lerp_angle(torso.rotation.y, target_angle, rotation_speed)


func look_at_direction(direction: Vector3) -> void:
	# convert to pitch and yaw for motor
	var horizontal_dir = Vector3(direction.x, 0, direction.z).normalized()
	_aim_target_yaw = atan2(horizontal_dir.x, horizontal_dir.z)

	# calculate pitch
	_aim_target_pitch = asin(clamp(-direction.y, -1.0, 1.0))

	rotate_aim()

#endregion







#region Helpers

func is_moving() -> bool:
	return body.velocity.length() > 0.01


func get_aim_torso_angle_difference() -> float:
	var angle := torso.global_rotation_degrees.y - aim_pivot.global_rotation_degrees.y
	angle = wrapf(angle, -180.0, 180.0) 
	angle = deg_to_rad(angle)
	return(angle)


func _get_aim_pitch(relative: Vector2) -> float:
	var new_pitch := _aim_target_pitch + relative.y
	var _max_pitch := deg_to_rad(max_head_pitch)
	var _min_pitch := deg_to_rad(-max_head_pitch)
	return clamp(new_pitch, _min_pitch, _max_pitch)


func _get_aim_yaw(relative: Vector2) -> float:
	return wrapf(_aim_target_yaw - relative.x, -PI, PI)


func has_move_input() -> bool:
	return input_direction.x != 0 or input_direction.y != 0


func _torso_too_twisted():
	return get_aim_torso_angle_difference() > deg_to_rad(45)

#endregion
