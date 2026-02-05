extends TateNode3D
class_name TateCharacterModel
## Rotates the stomach bone and provides simple API to work with an imported character model.

# NOTE: This needs to be refactored! It is using the deprecated IK
# and the fact it spawns the IK via code is something I don't like

@export var stomach_bone_name: String = "stomach"
@export var left_hand_target : Marker3D
@export var right_hand_target : Marker3D


var _skeleton: Skeleton3D
var _stomach_bone_index : int
var _meshes : Array[MeshInstance3D] = []
var _meshes_shown := true

var _left_hand_ik : SkeletonIK3D
var _right_hand_ik : SkeletonIK3D


var pitch : float = 0.0
var yaw : float = 0.0


func _ready() -> void:
	_skeleton = _get_first_skeleton()
	_stomach_bone_index = _skeleton.find_bone(stomach_bone_name)
	_meshes = _get_all_meshes()
	
	_check_warnings()


func _process(_delta):
	#var pitch := _aim_target.global_rotation.x #+ deg_to_rad(45)
	
	#var yaw = -(character.get_aim_torso_angle_difference())
	
	var final_basis = Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, pitch)
	
	_skeleton.set_bone_pose_rotation(_stomach_bone_index, Quaternion(final_basis))


#func assign_aim_target(target_node: Marker3D):
#	_aim_target = target_node


func hide_meshes():
	if _meshes_shown == false:
		return
	for mesh in _meshes:
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_SHADOWS_ONLY
	_meshes_shown = false


func show_meshes():
	if _meshes_shown:
		return
	for mesh in _meshes:
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_meshes_shown = true


func start_ik() -> void:
	_left_hand_ik.start()
	_right_hand_ik.start()


func stop_ik() -> void:
	_left_hand_ik.stop()
	_right_hand_ik.stop()


func _check_warnings() -> void:
	#if not _aim_target: 
	#	push_warning("WARNING: no _aim_target assigned under TateCharacterModel: ",get_path())
	if _stomach_bone_index == -1:
		push_warning("WARNING: no stomach bone with name <",
		stomach_bone_name,"> could not be found under TateCharacterModel: ", get_path())
	


func _get_all_meshes(_under_node : Node = self, _array : Array[MeshInstance3D] = []) -> Array[MeshInstance3D]:
	for child : Node in _under_node.get_children():
		if child.get_child_count() > 0:
			_get_all_meshes(child, _array)
		
		if child is MeshInstance3D:
			_array.append(child)
	
	return _array


func show_item():
	var item = right_hand_target.get_child(0).get_child(0)
	if item is MeshInstance3D:
		item.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


func _get_first_skeleton(_under_node : Node = self) -> Skeleton3D:
	for child : Node in _under_node.get_children():
		if child is Skeleton3D:
			return child
		
		if child.get_child_count() > 0:
			var result = _get_first_skeleton(child)
			if result != null:
				return result
	
	return null
