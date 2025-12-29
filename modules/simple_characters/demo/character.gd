extends Node3D

@onready var body: TateAdvancedCharacterMotor3D = $CharacterBody3D

@onready var mannequin: Node3D = $CharacterBody3D/Node3D
@onready var head: Marker3D = $CharacterBody3D/Node3D/Head
@onready var torso: Marker3D = $CharacterBody3D/Node3D/Torso
@onready var jump_particles: GPUParticles3D = $CharacterBody3D/JumpParticles
@onready var orbit_camera_pivot: Marker3D = $CharacterBody3D/Node3D/OrbitCameraPivot

@export var mouse_sensitivity := 0.0008
@export var vertical_sensitivity := 0.5
#@onready var camera_3d: Camera3D = $CharacterBody3D/Camera3D


@onready var first_person_camera: Camera3D = $CharacterBody3D/Node3D/Head/FirstPersonCamera
@onready var shoulder_camera: Camera3D = $CharacterBody3D/Node3D/Head/ShoulderCamera
@onready var orbit_camera: Camera3D = $CharacterBody3D/Node3D/OrbitCameraPivot/OrbitCamera
@onready var world_camera: Camera3D = $"../WorldCamera"

enum CameraState{
	FIRST_PERSON,
	SHOULDER,
	ORBIT,
	WORLD,
}

var current_camera_state := CameraState.SHOULDER

var max_pitch := 90.0

var head_yaw := 0.0
var pitch := 0.0
var extra_amount := 0.0
var input_direction := Vector2.ZERO
var free_cam := false

var half_spin := deg_to_rad(180)
var quarter_spin := deg_to_rad(45)


func _ready() -> void:
	shoulder_camera.make_current()


func _process(_delta: float) -> void:
	torso.global_position = body.global_position
	orbit_camera_pivot.global_position = body.global_position + Vector3.UP * 2
	
	if has_move_input():
		sync_torso_rotation_to_head()


func _on_pc_input_handler_move_input(new_input_direction: Vector2) -> void:
	body.input_direction = new_input_direction
	body.input_strength = 1.0
	
	input_direction = new_input_direction
	
	## NOTICE
	if not free_cam:
		if current_camera_state == CameraState.ORBIT:
			body.global_rotation.y = orbit_camera_pivot.global_rotation.y


### DEAL WITH ROTATION
func _on_pc_input_handler_look_input(mouse_relative: Vector2) -> void:
	pitch = get_pitch(mouse_relative)
	
	head_yaw = get_next_yaw(mouse_relative)
	
	if true:#not current_camera_state == CameraState.ORBIT:
		rotate_head()
		rotate_body()
	
	if not free_cam:
		orbit_camera_pivot.global_rotation.y = head.global_rotation.y + half_spin
		orbit_camera_pivot.global_rotation.x = -head.global_rotation.x
	#else:
		#rotate_orbit_camera_pivot(-(mouse_relative.x * mouse_sensitivity))
	
	
	rotate_body_with_camera()


#region Rotation

func rotate_head():
	#first_person_camera.rotation.x = pitch
	#print(pitch)
	
	var head_basis = Basis(Vector3.RIGHT, pitch) * Basis(Vector3.UP, deg_to_rad(180))
	head.basis = head_basis


func rotate_body():
	var yaw_final_amount := head_yaw + extra_amount
	
	var body_basis = Basis(Vector3.UP, yaw_final_amount)
	body.basis = body_basis


func rotate_body_with_camera():
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
	var strafe_amount := -body.input_direction.x
	var target_angle = body.rotation.y + half_spin + strafe_amount * quarter_spin
	var rotation_speed_multiplier := 0.02
	var rotation_speed : float = clamp(body.velocity.length() * rotation_speed_multiplier, 0.0, 0.9)
	torso.rotation.y = lerp_angle(torso.rotation.y, target_angle, rotation_speed)


func rotate_orbit_camera_pivot(next_yaw):
	orbit_camera_pivot.rotate_y(next_yaw)
	orbit_camera_pivot.rotation.x = pitch
	
	if not free_cam:
		var head_basis = Basis(Vector3.RIGHT, pitch) * Basis(Vector3.UP, deg_to_rad(180))
		head.basis = head_basis

#endregion

#region Helpers

func is_moving() -> bool:
	return body.velocity.length() > 0.01


func get_head_torso_angle_difference() -> float:
	var angle := torso.global_rotation_degrees.y - head.global_rotation_degrees.y
	angle = wrapf(angle, -180.0, 180.0) 
	angle = deg_to_rad(angle)
	return(angle)


func get_pitch(mouse_relative: Vector2) -> float:
	return clamp(pitch - (mouse_relative.y * mouse_sensitivity * vertical_sensitivity), deg_to_rad(-max_pitch), deg_to_rad(max_pitch))


func get_next_yaw(mouse_relative: Vector2) -> float:
	#print(rad_to_deg(head_yaw), " ", rad_to_deg(head.rotation.x))
	#return head_yaw - (mouse_relative.x * mouse_sensitivity)#wrapf(head_yaw - (mouse_relative.x * mouse_sensitivity),deg_to_rad(-180),deg_to_rad(180))
	return wrapf(head_yaw - (mouse_relative.x * mouse_sensitivity), -PI, PI)

func no_move_input() -> bool:
	return input_direction.length() == 0


func has_move_input() -> bool:
	return input_direction.length() != 0


#endregion

#region Jump

func _on_pc_input_handler_jump_pressed() -> void:
	if body.can_jump():
		body.jump()

func _on_pc_input_handler_jump_released() -> void:
	body.reset_jump()

func _on_character_body_3d_jumped() -> void:
	jump_particles.restart()

#endregion

#region Camera Zoom

func _on_pc_input_handler_zoom_in() -> void:
	camera_in()


func _on_pc_input_handler_zoom_out() -> void:
	camera_out()


func camera_in():
	if current_camera_state == CameraState.WORLD:
		current_camera_state = CameraState.SHOULDER
		shoulder_camera.make_current()
		mannequin.show()
	#elif current_camera_state == CameraState.ORBIT:
		#current_camera_state = CameraState.SHOULDER
		#mannequin.show()
		#shoulder_camera.make_current()
	elif current_camera_state == CameraState.SHOULDER:
		current_camera_state = CameraState.FIRST_PERSON
		mannequin.hide()
		first_person_camera.make_current()


func camera_out():
	mannequin.show()
	if current_camera_state == CameraState.FIRST_PERSON:
		current_camera_state = CameraState.SHOULDER
		shoulder_camera.make_current()
	elif current_camera_state == CameraState.SHOULDER:
		current_camera_state = CameraState.WORLD
		world_camera.make_current()
	#elif current_camera_state == CameraState.ORBIT:
	#	current_camera_state = CameraState.WORLD
	#	world_camera.make_current()

#endregion

#region Sprint

func _on_pc_input_handler_sprint_pressed() -> void:
	body.start_sprinting()


func _on_pc_input_handler_sprint_released() -> void:
	body.stop_sprinting()

#endregion

#region Free Cam

func _on_pc_input_handler_free_cam_pressed() -> void:
	free_cam = true


func _on_pc_input_handler_free_cam_released() -> void:
	free_cam = false

#endregion
