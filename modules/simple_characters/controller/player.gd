extends Node

@export var character : TateCharacter
@export var camera : Camera3D

@export var look_sensitivity := 0.0015
@export var vertical_sensitivity := 0.5

var first_person_camera_pivot : Marker3D
var shoulder_camera_pivot : Marker3D


func _process(_delta: float) -> void:
	first_person_camera_pivot = character.get_first_person_camera_pivot()
	shoulder_camera_pivot = character.get_shoulder_camera_pivot()
	
	
	#if first_person_camera_pivot:
	#	camera.global_position = first_person_camera_pivot.global_position
	#	camera.global_rotation = first_person_camera_pivot.global_rotation
	#	character.show_view_model()
	#	character.hide_character_model()
	
	camera.global_position = shoulder_camera_pivot.global_position
	camera.global_position = shoulder_camera_pivot.global_position
	
	#camera.global_position = character.first_person_camera_marker.global_position
	#camera.global_rotation = character.first_person_camera_marker.global_rotation
	
	#character.model.hide_meshes()
	#character.model.show_item()
	
	# this is used for the shoulder cam
	#camera.global_position = character.shoulder_camera_marker.global_position
	#camera.global_rotation = character.shoulder_camera_marker.global_rotation
	
	#character.model.show_meshes()

func _on_pc_input_controller_look_input(mouse_relative: Vector2) -> void:
	mouse_relative *= look_sensitivity
	mouse_relative.y *= vertical_sensitivity
	
	character.rotate_head_relative(mouse_relative)

func _on_pc_input_controller_move_input(input_direction: Vector2) -> void:
	character.input_direction = input_direction
	
	if input_direction.length() == 0.0:
		character.input_strength = 0.0
	else:
		character.input_strength = 1.0


func _on_pc_input_controller_jump_pressed() -> void:
	character.try_to_jump()


func _on_pc_input_controller_jump_released() -> void:
	character.reset_jump()


func _on_pc_input_controller_free_cam_pressed() -> void:
	character.is_free_looking = true


func _on_pc_input_controller_free_cam_released() -> void:
	character.is_free_looking = false
