extends TateNode
class_name TateCharacterAnimator

@export var visuals_sync_speed := 0.02
@export var lean_into_turn_amount := PI/4
@export var character : TateCharacter


func update_visuals() -> void:
	var strafe_amount := -character.input_direction.x * lean_into_turn_amount
	var rotation_speed : float = clamp(character.physics_body.velocity.length() * visuals_sync_speed, 0.1, 0.9)
	
	character.visuals_pivot.rotation.y = lerp_angle(character.visuals_pivot.rotation.y, strafe_amount, rotation_speed)
	character.visuals_pivot.rotation.z = lerp_angle(character.visuals_pivot.rotation.z, 0.05 * strafe_amount, rotation_speed)
	
	if not character.is_free_looking:
		character.character_model.pitch = character.camera_pivot.rotation.x
	character.character_model.yaw = -character.get_aim_torso_angle_difference()
