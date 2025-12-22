extends Node3D

@onready var body: TateCharacterMotor = $CharacterBody3D

@onready var mannequin: Node3D = $CharacterBody3D/Node3D
@onready var head: Marker3D = $CharacterBody3D/Node3D/Head
@onready var torso: Marker3D = $CharacterBody3D/Node3D/Torso

@export var mouse_sensitivity := 0.001
@export var vertical_sensitivity := 0.65
#@onready var camera_3d: Camera3D = $CharacterBody3D/Camera3D


@onready var first_person_camera: Camera3D = $CharacterBody3D/Node3D/Head/FirstPersonCamera
@onready var third_person_camera: Camera3D = $CharacterBody3D/ThirdPersonCamera
@onready var world_camera: Camera3D = $"../WorldCamera"


var head_yaw := 0.0
#var yaw := 0.0
var pitch := 0.0
var extra_amount := 0.0
#var sync_torso := false

var half_spin := deg_to_rad(180)
var quarter_spin := deg_to_rad(45)

func _process(_delta: float) -> void:
	torso.global_position = body.global_position
	
	## SPEED / VELOCITY
	if is_moving():
		sync_torso()


func sync_torso():
	if sync_torso:
		var strafe_amount := -body.input_direction.x
		
	
		var target_angle = body.rotation.y + half_spin + strafe_amount * quarter_spin
		#target_angle = wrapf(target_angle, -half_spin, half_spin)
		var rotation_speed_multiplier := 0.03
		var rotation_speed : float = clamp(body.velocity.length() * rotation_speed_multiplier, 0.0, 0.9)
		torso.rotation.y = lerp_angle(torso.rotation.y, target_angle, rotation_speed)



func _on_pc_input_handler_move_input(input_direction: Vector2) -> void:
	body.input_direction = input_direction
	body.input_strength = 1.0


### DEAL WITH ROTATION
func _on_pc_input_handler_look_input(mouse_relative: Vector2) -> void:
	#yaw = -(mouse_relative.x * mouse_sensitivity)
	
	## LIMIT PITCH
	var max_pitch := 90.0
	pitch = clamp(pitch - (mouse_relative.y * mouse_sensitivity * vertical_sensitivity), deg_to_rad(-max_pitch / 2), deg_to_rad(max_pitch / 2))
	
	## LIMIT HEAD_YAW
	#var max_yaw := 45.0
	var next_yaw = head_yaw - (mouse_relative.x * mouse_sensitivity)
	#if next_yaw > yaw_limit_rad:
	#	yaw_overflow(next_yaw - yaw_limit_rad)
		#yaw_overflow.emit(next_yaw - yaw_limit_rad)
	#	head_yaw = yaw_limit_rad
	#elif next_yaw < -yaw_limit_rad:
	#	yaw_overflow(next_yaw + yaw_limit_rad)
		#yaw_overflow.emit(next_yaw + yaw_limit_rad)
	#	head_yaw = -yaw_limit_rad
	#else:
	head_yaw = next_yaw
	
	#mannequin.set_head_rotation(head_yaw, pitch)
	
	first_person_camera.rotation.x = pitch
	
	var yaw_final_amount := head_yaw + extra_amount
	
	var body_basis = Basis(Vector3.UP, yaw_final_amount)
	body.basis = body_basis
	
	var head_basis = Basis(Vector3.RIGHT, pitch) * Basis(Vector3.UP, deg_to_rad(180))
	head.basis = head_basis
	
	var head_torso_angle_difference := get_head_torso_angle_difference()
	var yaw_limit := deg_to_rad(45)
	var torso_turn_around := 0.0
	
	
	if is_moving():
		return
	
	### ROTATING TORSO WITH THE CAMERA
	
	## RIGHT / CLOCKWISE
	if head_torso_angle_difference > yaw_limit :
		torso_turn_around = -abs(yaw_limit - head_torso_angle_difference)
		
		torso.rotate_y(torso_turn_around)
	
	## LEFT / ANTI-CLOCKWISE
	elif head_torso_angle_difference < -yaw_limit:
		torso_turn_around = abs(yaw_limit + head_torso_angle_difference)
		
		torso.rotate_y(abs(yaw_limit + head_torso_angle_difference))


func is_moving() -> bool:
	return body.velocity.length() > 0.01


func get_head_torso_angle_difference() -> float:
	var angle := torso.global_rotation_degrees.y - head.global_rotation_degrees.y
	angle = wrapf(angle, -180.0, 180.0) 
	angle = deg_to_rad(angle)
	return(angle)


func yaw_overflow(amount : float):
	#body.rotate_y(amount)
	extra_amount += amount
	#mannequin.rotate_y(amount)


func _on_pc_input_handler_zoom_in() -> void:
	camera_in()


func _on_pc_input_handler_zoom_out() -> void:
	camera_out()


func camera_in():
	if world_camera.current:
		third_person_camera.make_current()
		mannequin.show()
	elif third_person_camera.current:
		mannequin.hide()
		first_person_camera.make_current()

func camera_out():
	mannequin.show()
	if first_person_camera.current:
		third_person_camera.make_current()
	elif third_person_camera.current:
		world_camera.make_current()


func _on_pc_input_handler_jump_pressed() -> void:
	if body.can_jump():
		body.jump()


func _on_pc_input_handler_jump_released() -> void:
	body.reset_jump()
