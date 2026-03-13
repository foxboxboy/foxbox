extends Node

@export var character : FoxCharacter
@export var camera : Camera3D

@export var look_sensitivity := 0.0015
@export var vertical_sensitivity := 0.5

var first_person_camera_pivot : Marker3D
var shoulder_camera_pivot : Marker3D


const TOMMY_GUN = preload("uid://384do1qwb655")
const VEST = preload("uid://cu8c6xykn3112")
const HELMET = preload("uid://qalmtfjmgw2q")


func _process(_delta: float) -> void:
	
	first_person_camera_pivot = character.get_first_person_camera_pivot()
	shoulder_camera_pivot = character.get_shoulder_camera_pivot()
	
	do_third_person()


# i would put this in the input controlers but oh my god i am lazy
func _input(event: InputEvent) -> void:
	return
	
	if event is InputEventKey:
		if event.pressed and not event.echo:
			#CROUCH
			if event.keycode == KEY_C:
				character.wants_to_crouch = !character.wants_to_crouch

			
			# SPRINT
			if event.keycode == KEY_CTRL:
				character.wants_to_sprint = !character.wants_to_sprint
				
			
			# HOLD GUN
			if event.keycode == KEY_1:
				if character.hands.has_node_in_either_hand():
					character.hands.empty_hands()
				else:
					const TOMMY_GUN_ITEM = preload("uid://ww7unfyqu7q8")
					var new_gun : FoxHoldableItem = TOMMY_GUN_ITEM.instantiate()
					character.hands.hold_item(new_gun)
			
			# EQUIP HELMET
			if event.keycode == KEY_2:
				if character.accessories.has_rigid_accessory_in_slot("head"):
					character.accessories.empty_rigid_accessory_slot("head")
				else:
					character.accessories.equip_rigid_accessory(HELMET.instantiate(), "head")
			
			# EQUIP VEST
			if event.keycode == KEY_3:
				if character.accessories.has_skinned_accessory_slot("torso"):
					character.accessories.empty_skinned_accessory_slot("torso")
				else:
					character.accessories.equip_skinned_accessory(VEST.instantiate(), "torso")
			
			if event.keycode == KEY_E:
				print("nerp")
				
				const BULLET = preload("uid://cs86odgdio8ak")
				var new_bullet : Node3D = BULLET.instantiate()
				var target_position := first_person_camera_pivot.global_position + first_person_camera_pivot.global_basis.z
				var spawn_position := first_person_camera_pivot.global_position
				new_bullet.position = spawn_position
				get_parent().add_child(new_bullet)
				new_bullet.look_at(target_position)



func do_first_person():
	camera.global_position = first_person_camera_pivot.global_position
	camera.global_rotation = first_person_camera_pivot.global_rotation
	character.hide_character_model()


func do_third_person():
	camera.global_position = shoulder_camera_pivot.global_position
	camera.global_rotation = shoulder_camera_pivot.global_rotation
	character.show_character_model()



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



func _on_pc_input_controller_jump_held() -> void:
	if character.is_on_floor():
		character.request_jump()


func _on_pc_input_controller_free_cam_pressed() -> void:
	character.is_free_looking = true


func _on_pc_input_controller_free_cam_released() -> void:
	character.is_free_looking = false


func _on_pc_input_controller_jump_pressed() -> void:
	_trigger_jump_intent()
	character.request_jump()



func _trigger_jump_intent():
	character.request_jump()
	# If we don't land/jump within 0.1s, forget the intent.
	get_tree().create_timer(0.1).timeout.connect(
		func(): character.cancel_jump_request()
	)


func _on_pc_input_controller_dash_pressed() -> void:
	character.request_dash()


func _on_pc_input_controller_sprint_pressed() -> void:
	character.toggle_sprint_intent()


func _on_pc_input_controller_dash_released() -> void:
	character.cancel_dash_request()
