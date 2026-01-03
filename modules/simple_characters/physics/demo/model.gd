#@tool
## Model
extends Node3D

## Rotates the head bone.

@export var head_target: Marker3D
@export var skeleton_3d: Skeleton3D 
@export var character : TatePhysicsCharacter
@export var head_bone_name: String = "head"

@export var mesh : MeshInstance3D

var head_bone_idx : int


func _ready() -> void:
	head_bone_idx = skeleton_3d.find_bone(head_bone_name)


func _process(_delta: float) -> void:
	#if Engine.is_editor_hint():
	#	get_parent().global_position = character.rigid_body.global_position #+ Vector3(0,-1.138,0)
	#	return
	
	var pitch := head_target.global_rotation.x
	
	var yaw = -(character.get_head_torso_angle_difference())
	
	var final_basis = Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch)
	
	skeleton_3d.set_bone_pose_rotation(head_bone_idx, Quaternion(final_basis))


func hide_mesh():
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY


func show_mesh():
	mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
