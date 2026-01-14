extends Node

@export var character : Node3D
@export var camera : Camera3D

@export var look_sensitivity := 0.0015
@export var vertical_sensitivity := 0.5

func _process(_delta: float) -> void:
	#camera.global_position = character.first_person_camera_marker.global_position
	#camera.global_rotation = character.first_person_camera_marker.global_rotation
	
	# this is used for the shoulder cam
	camera.global_position = character.shoulder_camera_marker.global_position
	camera.global_rotation = character.shoulder_camera_marker.global_rotation
	
	#character.character_model.show_meshes()

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
