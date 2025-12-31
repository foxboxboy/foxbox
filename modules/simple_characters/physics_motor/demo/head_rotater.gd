@tool
## Head Rotater
extends Node3D

## Rotates the head bone.

@export var head_target: Marker3D
@export var skeleton_3d: Skeleton3D 
@export var character : TatePhysicsCharacter
@export var head_bone_name: String = "head"
@export var anim_player : AnimationPlayer


var time_since_last_update = 0.0




func _process(delta: float) -> void:
	#process_mode = Node.PROCESS_MODE_DISABLED
	if Engine.is_editor_hint():
		get_parent().global_position = character.rigid_body.global_position #+ Vector3(0,-1.138,0)
		return
	
	#character.ri.process_mode = Node.PROCESS_MODE_DISABLED
	
	#anim_lod(delta)
	
	var head_bone_idx = skeleton_3d.find_bone(head_bone_name)
	
	var pitch := head_target.global_rotation.x
	
	var yaw = -(character.get_head_torso_angle_difference())
	
	var final_basis = Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch)
	
	skeleton_3d.set_bone_pose_rotation(head_bone_idx, Quaternion(final_basis))



func anim_lod(delta):
	var camera = get_viewport().get_camera_3d()
	
	if camera == null:
		return
	
	# 1. Get distance to camera
	var dist = global_position.distance_to(camera.global_position)
	
	# 2. Determine "Animation FPS" based on distance
	var target_fps = 60.0
	if dist > 50: target_fps = 60.0   # Very far: 5 frames per second
	elif dist > 8: target_fps = 60.0 # Mid range: 12 frames per second
	elif dist > 1: target_fps = 60.0 # Close-mid: 30 frames per second
	
	# 3. Only advance the animation if enough time has passed
	time_since_last_update += delta
	var update_interval = 1.0 / target_fps
	
	if time_since_last_update >= update_interval:
		# Pushes the animation forward by the time that has passed
		anim_player.advance(time_since_last_update)
		time_since_last_update = 0.0
