class_name FoxCharacterAimManager
extends FoxNode3D
## Component that handles head rotation, camera pivots, free-look, and height tweening.

@export_group("Components")
@export var parent_body: Node3D
@export var shoulder_camera_pivot: Marker3D
@export var first_person_camera_pivot: Marker3D

@export_group("Height Settings")
@export var stand_height: float = 2.0
@export var crouch_height: float = 1.0
@export var prone_height: float = 0.4

@export_group("Aim Settings")
@export var max_head_pitch_deg := 89.0

var is_free_looking := false : set = _set_is_free_looking

var _aim_target_pitch: float = 0.0
var _max_head_pitch_rad: float
var _free_look_yaw_offset: float = 0.0


func _ready() -> void:
	stand()
	_max_head_pitch_rad = deg_to_rad(max_head_pitch_deg)
	assert(shoulder_camera_pivot != null, "ERROR: No shoulder_camera_pivot assigned to FoxCharacterCameraPivot: " + str(get_path()))
	assert(first_person_camera_pivot != null, "ERROR: No first_person_camera_pivot assigned to FoxCharacterCameraPivot: " + str(get_path()))


func _process(_delta: float) -> void:
	# Snaps the head back to center when free-look is released
	if not is_free_looking and _free_look_yaw_offset != 0.0:
		_free_look_yaw_offset = 0.0
		rotation.y = _free_look_yaw_offset


#region Posture & Height

func stand() -> void:
	_animate_shape(stand_height)

func crouch() -> void:
	_animate_shape(crouch_height)
	
func prone() -> void:
	_animate_shape(prone_height)

func _animate_shape(target_y: float) -> void:
	var tween = create_tween().set_parallel(true)
	tween.tween_property(self, "position:y", target_y, 0.2)

#endregion


#region Aim & Rotation

## Accepts raw mouse/joystick delta to rotate the head.
func rotate_head_relative(relative: Vector2) -> void:
	# Pitch (Up/Down)
	_aim_target_pitch = clamp(_aim_target_pitch - relative.y, -_max_head_pitch_rad, _max_head_pitch_rad)
	rotation.x = _aim_target_pitch
	
	# Yaw (Left/Right)
	if is_free_looking:
		_free_look_yaw_offset -= relative.x
		rotation.y = _free_look_yaw_offset
	else:
		print("ROTATE ", -relative.x)
		parent_body.rotate_y(-relative.x)

## Instantly snaps the character's yaw and head pitch to target the spatial position.
func look_at_position(target_global_pos: Vector3, parent_body: Node3D) -> void:
	var direction = target_global_pos - global_position
	if direction.length_squared() < 0.001: return

	var target_yaw = atan2(-direction.x, -direction.z)
	parent_body.global_rotation.y = target_yaw
	
	var flat_distance = Vector2(direction.x, direction.z).length()
	var target_pitch = atan2(direction.y, flat_distance)
	
	_aim_target_pitch = clamp(target_pitch, -_max_head_pitch_rad, _max_head_pitch_rad)
	rotation.x = _aim_target_pitch

## Returns the current pitch to feed to the visual model's spine.
func get_pitch() -> float:
	return _aim_target_pitch

func _set_is_free_looking(value: bool) -> void:
	is_free_looking = value

#endregion
