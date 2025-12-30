extends Node3D

#region Export Variables

@export_group("Body Parts")
@export var body: TateAdvancedCharacterMotor3D
@export var mannequin: Node3D
@export var head: Marker3D
@export var torso: Marker3D

@export_group("Extras")
@export var jump_particles: GPUParticles3D

@export_group("Camera Settings")
@export var mouse_sensitivity := 0.0008
@export var vertical_sensitivity := 0.5
@export var max_camera_pitch := 90.0

@export_group("Cameras")
@export var first_person_camera: Camera3D
@export var shoulder_camera: Camera3D
@export var world_camera: Camera3D

#endregion







#region Variables

enum CameraState{
	FIRST_PERSON,
	SHOULDER,
	ORBIT,
	WORLD,
}

var current_camera_state := CameraState.SHOULDER

var head_yaw := 0.0
var pitch := 0.0
var extra_amount := 0.0
var input_direction := Vector2.ZERO
var free_cam := false

var half_spin := deg_to_rad(180)
var quarter_spin := deg_to_rad(45)

#endregion







#region Ready & Process

func _ready() -> void:
	shoulder_camera.make_current()


func _process(_delta: float) -> void:
	torso.global_position = body.global_position
	
	if has_move_input():
		sync_torso_rotation_to_head()

#endregion







#region Main Input

func _on_pc_input_handler_move_input(new_input_direction: Vector2) -> void:
	body.input_direction = new_input_direction
	body.input_strength = 1.0
	
	input_direction = new_input_direction


func _on_pc_input_handler_look_input(mouse_relative: Vector2) -> void:
	pitch = get_pitch(mouse_relative)
	
	head_yaw = get_next_yaw(mouse_relative)
	
	if true:
		rotate_head()
		rotate_body()
	
	rotate_body_with_head()

#endregion







#region Rotation

func rotate_head():
	var head_basis = Basis(Vector3.RIGHT, pitch) * Basis(Vector3.UP, deg_to_rad(180))
	head.basis = head_basis


func rotate_body():
	var yaw_final_amount := head_yaw + extra_amount
	
	var body_basis = Basis(Vector3.UP, yaw_final_amount)
	body.basis = body_basis


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
	var strafe_amount := -body.input_direction.x
	var target_angle := body.rotation.y + half_spin + strafe_amount * quarter_spin
	var rotation_speed_multiplier := 0.02
	var rotation_speed : float = clamp(body.velocity.length() * rotation_speed_multiplier, 0.0, 0.9)
	torso.rotation.y = lerp_angle(torso.rotation.y, target_angle, rotation_speed)

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
	var new_pitch := pitch - (mouse_relative.y * mouse_sensitivity * vertical_sensitivity)
	var _max_pitch := deg_to_rad(max_camera_pitch)
	var _min_pitch := deg_to_rad(-max_camera_pitch)
	return clamp(new_pitch, _min_pitch, _max_pitch)


func get_next_yaw(mouse_relative: Vector2) -> float:
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
