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

var pitch : float = 0.0
var yaw : float = 0.0


func _ready() -> void:
	_skeleton = _get_first_skeleton()
	_stomach_bone_index = _skeleton.find_bone(stomach_bone_name)
	_meshes = _get_all_meshes()
	
	_check_warnings()

func _process(delta):
	#$blockbench_export/AnimationPlayer.play("")
	$blockbench_export/AnimationPlayer.speed_scale = 1.5
	
# 1. Get Indices
	var spine_idx = _stomach_bone_index
	var parent_idx = _skeleton.get_bone_parent(spine_idx) # Get the Hips/Pelvis

	# 2. Calculate the ANIMATED Global Position manually
	# We do this to bypass the "Frozen" override on the spine
	
	# Get Parent Global (The Hips are moving up/down from the walk cycle)
	var parent_global = _skeleton.get_bone_global_pose(parent_idx)
	
	# Get Spine Local (The offset from Hips to Spine defined in the animation)
	# get_bone_pose() always returns the clean Animation data!
	var spine_local = _skeleton.get_bone_pose(spine_idx)
	
	# Combine them to find where the spine SHOULD be right now
	var animated_global_origin = (parent_global * spine_local).origin
	
	# 3. Calculate Rotation (Same as before)
	# We use Global Rest for rotation to keep aim steady and avoid twisting loops
	var rest_global = _skeleton.get_bone_global_rest(spine_idx)
	var aim_quat = Quaternion.from_euler(Vector3(pitch, yaw, 0))
	var final_basis = Basis(aim_quat) * rest_global.basis
	
	# 4. Apply Override
	# Use 'final_basis' for Rotation (Your Aim)
	# Use 'animated_global_origin' for Position (The Walk Cycle Bounce)
	var target_transform = Transform3D(final_basis, animated_global_origin)
	
	_skeleton.set_bone_global_pose_override(spine_idx, target_transform, 1.0, true)

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
