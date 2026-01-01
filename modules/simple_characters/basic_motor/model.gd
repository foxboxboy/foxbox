extends Node3D

## Rotates the head bone.

@onready var head_bone_attachment: BoneAttachment3D = $armature/Skeleton3D/HeadBoneAttachment
@onready var head: Node3D = $"../../Head"

@onready var skeleton_3d: Skeleton3D = $armature/Skeleton3D
@onready var character: Node3D = $"../../../.."

@export var head_bone_name: String = "head"

var head_yaw := 0.0


func _process(_delta: float) -> void:
	var head_bone_idx = skeleton_3d.find_bone(head_bone_name)
	
	var pitch := -head.global_rotation.x
	
	var yaw = -(character.get_head_torso_angle_difference())
	
	var final_basis = Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch)
	
	skeleton_3d.set_bone_pose_rotation(head_bone_idx, Quaternion(final_basis))
