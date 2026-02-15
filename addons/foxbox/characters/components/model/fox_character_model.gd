extends FoxNode3D
class_name FoxCharacterModel
## Rotates the spine bone and provides simple API to work with an imported character model.

@export_group("Components")
@export var character_animation_tree : FoxCharacterAnimationTree 
@export var character_hands : FoxCharacterHands

@export_group("Bones")
@export var spine_bone_name: String = "spine"

@export_group("Leaning")
#@export var visuals_sync_speed := 0.02
@export var lean_into_turn_amount := PI/4
@export var animation_spine_pitch_offset : float = 0.0


var _skeleton: Skeleton3D
var _spine_bone_index : int
var _pelvis_bone_index : int
var _meshes : Array[MeshInstance3D] = []
var _meshes_shown := true

var _smoothed_anim_transform : Transform3D

var pitch : float = 0.0
var yaw : float = 0.0






#region Ready & Process

func _ready() -> void:
	_skeleton = _get_first_skeleton()
	_spine_bone_index = _skeleton.find_bone(spine_bone_name)
	_pelvis_bone_index = _skeleton.get_bone_parent(_spine_bone_index)
	_meshes = _get_all_meshes()
	
	var pelvis = _skeleton.get_bone_global_pose(_pelvis_bone_index)
	var spine = _skeleton.get_bone_pose(_spine_bone_index)
	_smoothed_anim_transform = pelvis * spine
	
	_check_warnings()


func _process(_delta):
	_update_spine_bone()

#endregion







#region Public API

func enter_air() -> void:
	character_animation_tree.transition_to_air()	


func update_strafe(input_direction: Vector2) -> void:
	var strafe_amount := -input_direction.x * lean_into_turn_amount
	#var rotation_speed : float = clamp(horizontal_speed * visuals_sync_speed, 0.1, 0.9)
	
	rotation.y = strafe_amount#lerp_angle(rotation.y, strafe_amount, rotation_speed)
	rotation.z = 0.05 * strafe_amount#lerp_angle(rotation.z, 0.05 * strafe_amount, rotation_speed)


func update_pitch_and_yaw(new_pitch : float, new_yaw : float):
	self.pitch = new_pitch
	self.yaw = new_yaw


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


func stand():
	character_animation_tree.transition_to_stand()


func crouch():
	character_animation_tree.transition_to_crouch()


func set_move_speed(speed_percent: float) -> void:
	character_animation_tree.update_movement(speed_percent)


func set_vertical_speed(vertical_speed: float) -> void:
	character_animation_tree.update_air_physics(vertical_speed)

#endregion






#region Private

func _check_warnings() -> void:
	if _spine_bone_index == -1:
		push_warning("WARNING: no spine bone with name <",
		spine_bone_name,"> could not be found under FoxCharacterModel: ", get_path())
	


func _get_all_meshes(_under_node : Node = self, _array : Array[MeshInstance3D] = []) -> Array[MeshInstance3D]:
	for child : Node in _under_node.get_children():
		if child.get_child_count() > 0:
			_get_all_meshes(child, _array)
		
		if child is MeshInstance3D:
			_array.append(child)
	
	return _array


func _get_first_skeleton(_under_node : Node = self) -> Skeleton3D:
	for child : Node in _under_node.get_children():
		if child is Skeleton3D:
			return child
		
		if child.get_child_count() > 0:
			var result = _get_first_skeleton(child)
			if result != null:
				return result
	
	return null




func _update_spine_bone():
	var pelvis_global = _skeleton.get_bone_global_pose(_pelvis_bone_index)
	var spine_local = _skeleton.get_bone_pose(_spine_bone_index)

	# where the spine bone would be if we didn't touch it
	var animated_global_transform = pelvis_global * spine_local
	
	# our offset from where the character is looking
	var aim_basis = Basis.from_euler(Vector3(pitch, yaw, 0))
	
	# combine
	var final_basis = animated_global_transform.basis * aim_basis
	
	# apply
	var target_transform = Transform3D(final_basis, animated_global_transform.origin)
	_skeleton.set_bone_global_pose_override(_spine_bone_index, target_transform, 1.0, true)


#endregion
