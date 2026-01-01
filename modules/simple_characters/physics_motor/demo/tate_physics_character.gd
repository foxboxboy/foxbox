## Physics Character
extends TateComponent3D
class_name TatePhysicsCharacter

@onready var model: Node3D = $Torso/Model

@export_group("Components")
@export var head_target_marker: Marker3D
@export var torso : Node3D
@export var physics_motor: TatePhysicsCharacterMotor3D
@export var rigid_body : RigidBody3D
@export var forward_marker : Marker3D

@export_group("Camera Markers")
@export var shoulder_camera_marker : Marker3D
@export var first_person_camera_marker : Marker3D
@export var camera_pivot : Marker3D

@export_group("Look")
@export var look_sensitivity := 0.0015
@export var vertical_sensitivity := 0.5
@export var max_head_pitch := 90.0


var head_target_pitch : float
var head_target_yaw : float

#var last_relative_position := Vector2.ZERO
var input_direction := Vector2.ZERO:
	get:
		return physics_motor.input_direction
	set(new_value):
		physics_motor.input_direction = new_value.normalized()
		
		if has_move_input():
			rotate_head()

var input_strength := 0.0:
	get:
		return physics_motor.input_strength
	set(new_value):
		physics_motor.input_strength = new_value







#region Ready & Process

func _ready() -> void:
	#process_mode = Node.PROCESS_MODE_DISABLED
	
	assert(physics_motor != null, "ERROR: No physics_motor was assigned to character. "+str(get_path()))


func _physics_process(_delta: float) -> void:
#	torso.global_position = rigid_body.global_position
	
	forward_marker.global_rotation.y = head_target_marker.global_rotation.y





func _process(_delta: float) -> void:
	var camera := get_viewport().get_camera_3d()
	if not camera:
		return
	var dist_sq = global_position.distance_squared_to(camera.global_position)
	
	## NOTICE THIS CURRENTLY ISN'T DOING ANYTHING (the distance is really big)
	## Avoid using SQRT, it's not needed since we can do the calculation before
	## hand. If you want say 100, make the distance 100*100 = 10000.
	physics_motor.process_mode = Node.PROCESS_MODE_INHERIT
	if dist_sq > 250:
		if model.process_mode != Node.PROCESS_MODE_DISABLED:
			#physics_motor.process_mode = Node.PROCESS_MODE_DISABLED
			#physics_motor.set_physics_process(false)
			model.process_mode = Node.PROCESS_MODE_DISABLED
		
		
		#if is_physics_processing():
			#set_physics_process(false)
	else:
		if model.process_mode != Node.PROCESS_MODE_INHERIT:
			#physics_motor.process_mode = Node.PROCESS_MODE_INHERIT
			#physics_motor.set_physics_process(true)
			model.process_mode = Node.PROCESS_MODE_INHERIT

		if is_physics_processing() and has_move_input():
			sync_torso_rotation_to_head()
		#if not is_physics_processing():
			#set_physics_process(true)
	



#endregion





#region Main Input

func rotate_head_relative(relative: Vector2) -> void:
	head_target_pitch = _get_head_pitch(relative)
	
	head_target_yaw = _get_next_yaw(relative)
	
	rotate_camera_pivot()
	
	if has_move_input():
		rotate_head()
	
	rotate_body_with_head()


func try_to_jump() -> void:
	if physics_motor.can_jump():
		physics_motor.jump()

#endregion







#region Rotation

func rotate_camera_pivot():
	var yaw_basis := Basis(Vector3.UP, head_target_yaw + deg_to_rad(180))
	var pitch_basis = Basis(Vector3.LEFT, head_target_pitch)
	camera_pivot.basis = yaw_basis * pitch_basis


func rotate_head():
	var yaw_basis := Basis(Vector3.UP, head_target_yaw + deg_to_rad(180))
	var pitch_basis = Basis(Vector3.LEFT, head_target_pitch)
	head_target_marker.basis = yaw_basis * pitch_basis


func rotate_body_with_head():
	var head_torso_angle_difference := get_head_torso_angle_difference()
	var yaw_limit := deg_to_rad(45)
	var torso_turn_around := 0.0

	## RIGHT / CLOCKWISE
	if head_torso_angle_difference > yaw_limit :
		torso_turn_around = -abs(yaw_limit - head_torso_angle_difference)
		
		torso.rotate_y(torso_turn_around)
	
	## LEFT / ANTI-CLOCKWISE
	elif head_torso_angle_difference < -yaw_limit:
		torso_turn_around = abs(yaw_limit + head_torso_angle_difference)
		
		torso.rotate_y(abs(yaw_limit + head_torso_angle_difference))


func sync_torso_rotation_to_head():
	var strafe_amount := -physics_motor.input_direction.x
	var target_angle := head_target_marker.rotation.y + PI/2 + strafe_amount * PI/4
	var rotation_speed_multiplier := 0.02
	var rotation_speed : float = clamp(rigid_body.linear_velocity.length() * rotation_speed_multiplier, 0.0, 0.9)
	torso.rotation.y = lerp_angle(torso.rotation.y, target_angle, rotation_speed)


func look_at_direction(direction: Vector3) -> void:
	# Convert a 3D direction into the Pitch and Yaw your Motor expects
	var horizontal_dir = Vector3(direction.x, 0, direction.z).normalized()
	head_target_yaw = atan2(horizontal_dir.x, horizontal_dir.z)

	# Calculate pitch based on the Y component
	head_target_pitch = asin(clamp(-direction.y, -1.0, 1.0))

	rotate_head()
	rotate_body_with_head()

#endregion







#region Helpers

func is_moving() -> bool:
	return rigid_body.linear_velocity.length() > 0.01


func get_head_torso_angle_difference() -> float:
	var angle := torso.global_rotation_degrees.y - head_target_marker.global_rotation_degrees.y
	angle = wrapf(angle, -180.0, 180.0) 
	angle = deg_to_rad(angle)
	return(angle)


func _get_head_pitch(relative: Vector2) -> float:
	var new_pitch := head_target_pitch - (-relative.y * look_sensitivity * vertical_sensitivity)
	var _max_pitch := deg_to_rad(max_head_pitch)
	var _min_pitch := deg_to_rad(-max_head_pitch)
	return clamp(new_pitch, _min_pitch, _max_pitch)


func _get_next_yaw(relative: Vector2) -> float:
	return wrapf(head_target_yaw - (relative.x * look_sensitivity), -PI, PI)


func has_move_input() -> bool:
	return input_direction.length() != 0


#endregion
