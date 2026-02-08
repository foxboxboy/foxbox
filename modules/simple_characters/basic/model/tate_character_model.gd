extends TateNode3D
class_name TateCharacterModel
## Rotates the stomach bone and provides simple API to work with an imported character model.

# NOTE: This needs to be refactored! It is using the deprecated IK
# and the fact it spawns the IK via code is something I don't like

@export var stomach_bone_name: String = "stomach"
@export var left_hand_target : Marker3D
@export var right_hand_target : Marker3D
@export var left_hand_ik : CCDIK3D
@export var right_hand_ik : CCDIK3D


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

func _process(_delta):
	#$blockbench_export/AnimationPlayer.play("run")
	#$blockbench_export/AnimationPlayer.speed_scale = 1.0
	
	var pitch_offset := -0.0
	
	# 1. Get Indices
	var spine_idx = _stomach_bone_index
	var parent_idx = _skeleton.get_bone_parent(spine_idx) # Get the Hips/Pelvis


	#wleft_hand_ik.active = false
	#right_hand_ik.active = false

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
	var aim_quat = Quaternion.from_euler(Vector3(pitch + deg_to_rad(pitch_offset), yaw, 0))
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


@export var visuals_sync_speed := 0.02
@export var lean_into_turn_amount := PI/4


func update_visuals(input_direction: Vector2, speed: float, pitch: float, yaw: float) -> void:
	# 1. Handle Leaning (Internal Logic)
	var strafe_amount := -input_direction.x * lean_into_turn_amount
	var rotation_speed : float = clamp(speed * visuals_sync_speed, 0.1, 0.9)
	
	# We assume this script is ON the mesh or pivot, so we rotate 'self' or 'parent'
	# If this script is on the Model, and the Model is child of Pivot:
	rotation.y = lerp_angle(rotation.y, strafe_amount, rotation_speed)
	rotation.z = lerp_angle(rotation.z, 0.05 * strafe_amount, rotation_speed)
	
	# 2. Handle Aiming (Data passed in)
	self.pitch = pitch
	self.yaw = yaw
	
	
	update_animations(Vector3(input_direction.x,0.0,input_direction.y),false)



@export var anim_tree : AnimationTree
@onready var state_machine = anim_tree.get("parameters/playback")

func update_animations(velocity: Vector3, is_crouching: bool):
	# 1. Calculate horizontal speed (ignore jumping/falling speed)
	var horizontal_vel = Vector2(velocity.x, velocity.z)
	var speed = horizontal_vel.length() * 0.5
	
	# 2. Drive the State Machine
	if is_crouching:
		state_machine.travel("crouch")
		# Update the Crouch BlendSpace value
		anim_tree.set("parameters/crouch/blend_position", speed)
	else:
		state_machine.travel("stand")
		# Update the Stand BlendSpace value
		anim_tree.set("parameters/stand/blend_position", speed)
		
