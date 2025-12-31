## Head Rotater
extends Node3D

## Rotates the head bone.

@export var head_target: Marker3D
@export var skeleton_3d: Skeleton3D 
@export var character : Node3D
@export var head_bone_name: String = "head"

var head_yaw := 0.0


func _process(_delta: float) -> void:
	var head_bone_idx = skeleton_3d.find_bone(head_bone_name)
	
	var pitch := head_target.global_rotation.x
	
	var yaw = -(character.get_head_torso_angle_difference())
	
	var final_basis = Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch)
	
	skeleton_3d.set_bone_pose_rotation(head_bone_idx, Quaternion(final_basis))
