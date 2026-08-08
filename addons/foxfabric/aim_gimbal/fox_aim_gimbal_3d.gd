@tool
@icon("uid://ojs7ufmt2oci")
class_name FoxAimGimbal3D
extends Node3D
## A mathematical hinge that accumulates 2D input into safe 3D pitch and yaw rotations.
##
## Useful for camera controllers, turrets, or any object that requires
## clamped or wrapped two-axis rotation without encountering gimbal lock.

@export_group("Pitch")
## If [code]true[/code], restricts the X-axis rotation between [member min_pitch_deg] and [member max_pitch_deg].
## If [code]false[/code], wraps the rotation infinitely.
@export var clamp_pitch: bool = true
## The minimum allowed pitch in degrees. Evaluated only if [member clamp_pitch] is [code]true[/code].
@export var min_pitch_deg: float = -89.0
## The maximum allowed pitch in degrees. Evaluated only if [member clamp_pitch] is [code]true[/code].
@export var max_pitch_deg: float = 89.0

@export_group("Yaw")
## If [code]true[/code], restricts the Y-axis rotation between [member min_yaw_deg] and [member max_yaw_deg].
## If [code]false[/code], wraps the rotation infinitely.
@export var clamp_yaw: bool = false
## The minimum allowed yaw in degrees. Evaluated only if [member clamp_yaw] is [code]true[/code].
@export var min_yaw_deg: float = -90.0
## The maximum allowed yaw in degrees. Evaluated only if [member clamp_yaw] is [code]true[/code].
@export var max_yaw_deg: float = 90.0

## The current pitch (X-axis rotation) in radians. Modifying this safely updates the node's rotation.
var pitch: float = 0.0 :
	set(value):
		if clamp_pitch:
			pitch = clamp(value, deg_to_rad(min_pitch_deg), deg_to_rad(max_pitch_deg))
		else:
			pitch = wrapf(value, -PI, PI)
		rotation.x = pitch

## The current yaw (Y-axis rotation) in radians. Modifying this safely updates the node's rotation.
var yaw: float = 0.0 :
	set(value):
		if clamp_yaw:
			yaw = clamp(value, deg_to_rad(min_yaw_deg), deg_to_rad(max_yaw_deg))
		else:
			yaw = wrapf(value, -PI, PI)
		rotation.y = yaw


## Accumulates a 2D input delta (e.g., from a mouse or joystick) and applies it to the node's rotation.
## The Y component affects pitch (X-axis) and the X component affects yaw (Y-axis).
func apply_rotation_input(input_delta: Vector2) -> void:
	pitch -= input_delta.y
	yaw -= input_delta.x


## Intercepts native look_at calls to prevent internal pitch/yaw desyncs.
func look_at(target: Vector3, up: Vector3 = Vector3.UP, use_model_front: bool = false) -> void:
	push_warning("FoxAimGimbal3D: Native look_at() intercepted. Routing to aim_at_position() to maintain gimbal limits.")
	aim_at_position(target)


## Instantly calculates the pitch and yaw required to face a global 3D position,
## then safely feeds them through the clamps.
func aim_at_position(target_global_pos: Vector3) -> void:
	var parent = get_parent_node_3d()
	var target_dir: Vector3
	
	if parent:
		target_dir = parent.to_local(target_global_pos) - position
	else:
		target_dir = target_global_pos - global_position
		
	if target_dir.length_squared() < 0.001:
		return
		
	var target_yaw = atan2(-target_dir.x, -target_dir.z)
	
	var flat_distance = Vector2(target_dir.x, target_dir.z).length()
	var target_pitch = atan2(target_dir.y, flat_distance)
	
	pitch = target_pitch
	yaw = target_yaw




#region Editor

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []

	if clamp_pitch and min_pitch_deg > max_pitch_deg:
		warnings.append("Min Pitch Deg is above Max Pitch Deg, so pitch is clamped to an "
			+ "inverted range.")

	if clamp_yaw and min_yaw_deg > max_yaw_deg:
		warnings.append("Min Yaw Deg is above Max Yaw Deg, so yaw is clamped to an inverted "
			+ "range.")

	return warnings

#endregion
