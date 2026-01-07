## Physics Character
extends TateNode3D
class_name TatePhysicsCharacter

## WARNING remove or refactor this later this is pretty stupid
@onready var model: Node3D = $Torso/Model

@export_group("Components")
@export var head_target_marker: Marker3D
@export var torso : Node3D
@export var physics_motor: TatePhysicsCharacterMotor3D
@export var rigid_body : RigidBody3D
@export var forward_marker : Marker3D

@export_group("Camera Markers")
@export var shoulder_camera_marker : Marker3D
@export var first_person_camera_marker : Marker3D
@export var camera_pivot : Marker3D

@export_group("Look")
@export var look_sensitivity := 0.0015
@export var vertical_sensitivity := 0.5
@export var max_head_pitch := 89.0


@export_group("Shadow")

@export var shadow_decal_scene: PackedScene
@export var shadow_simple_scene: PackedScene

@export var shadow_simple_y_offset : float = 0.025
@export var shadow_decal_y_offset : float = -0.975

@export var shadow_type := ShadowQuality.DISABLED:
	set = _set_shadow_quality



@export_group("Visual Optimizer")

@export var visual_optimizer : TateVisualOptimizer


var head_target_pitch : float
var head_target_yaw : float

#var last_relative_position := Vector2.ZERO
var input_direction := Vector2.ZERO:
	set(new_value):
		var new_value_normalized := new_value.normalized()
		physics_motor.input_direction = new_value_normalized
		
		# NOTICE has_move_input() optimization
		if (input_direction.x != 0 or input_direction.y != 0):
			rotate_head()
		
		input_direction = new_value_normalized

var input_strength := 0.0:
	set(new_value):
		input_strength = clampf(new_value, 0.0, 1.0)
		physics_motor.input_strength = new_value

enum ShadowQuality{
	## No shadow will be shown under this character.
	DISABLED,
	## A simple mesh instance with a black circle will
	## be shown. 
	SIMPLE,
	## A more advanced decal will be used to draw the
	## shadow.
	DECAL,
}

var shadow: Node









#region Ready & Process

func _ready() -> void:
	
	assert(physics_motor != null, "ERROR: No physics_motor was assigned to character. "+str(get_path()))


func _physics_process(_delta: float) -> void:
	
	# NOTICE has_move_input() optimization
	if input_direction.x != 0 or input_direction.y != 0:
		forward_marker.global_rotation.y = head_target_marker.global_rotation.y


func _process(_delta: float) -> void:
	
	if visual_optimizer:
		if visual_optimizer.is_far:
			return
		
	# NOTICE has_move_input() optimization
	if is_physics_processing() and (input_direction.x != 0 or input_direction.y != 0):
		sync_torso_rotation_to_head()



#endregion





#region Multiplayer

func set_network_role(is_authority: bool):
	## SERVER
	if is_authority:
		# turn on physics & logic
		physics_motor.process_mode = Node.PROCESS_MODE_INHERIT
		physics_motor.jump_cast.enabled = true
		set_physics_process(true)
		
		rigid_body.freeze = false

	## CLIENT
	else:
		physics_motor.process_mode = Node.PROCESS_MODE_DISABLED
		physics_motor.jump_cast.enabled = false
		set_physics_process(false)

		# NOTICE
		# make body purely visual/kinematic so it doesn't fight the sync
		rigid_body.freeze = true

#endregion







#region Main Input

func rotate_head_relative(relative: Vector2) -> void:
	head_target_pitch = _get_head_pitch(relative)
	
	head_target_yaw = _get_next_yaw(relative)
	
	if camera_pivot:
		rotate_camera_pivot()
	
	# NOTICE has_move_input() optimization
	if (input_direction.x != 0 or input_direction.y != 0):
		rotate_head()
	
	rotate_body_with_head()


func try_to_jump() -> void:
	if physics_motor.can_jump():
		physics_motor.jump()

#endregion







#region Rotation

func rotate_camera_pivot():
	var yaw_basis := Basis(Vector3.UP, head_target_yaw + deg_to_rad(180))
	var pitch_basis = Basis(Vector3.LEFT, head_target_pitch)
	camera_pivot.basis = yaw_basis * pitch_basis


func rotate_head():
	var yaw_basis := Basis(Vector3.UP, head_target_yaw + deg_to_rad(180))
	var pitch_basis = Basis(Vector3.LEFT, head_target_pitch)
	head_target_marker.basis = yaw_basis * pitch_basis


func rotate_body_with_head():
	var head_torso_angle_difference := get_head_torso_angle_difference()
	var yaw_limit := deg_to_rad(45)
	var torso_turn_around := 0.0

	## RIGHT / CLOCKWISE
	if head_torso_angle_difference > yaw_limit :
		torso_turn_around = -abs(yaw_limit - head_torso_angle_difference)
		
		torso.rotate_y(torso_turn_around)
	
	## LEFT / ANTI-CLOCKWISE
	elif head_torso_angle_difference < -yaw_limit:
		torso_turn_around = abs(yaw_limit + head_torso_angle_difference)
		
		torso.rotate_y(abs(yaw_limit + head_torso_angle_difference))


func sync_torso_rotation_to_head():
	var strafe_amount := -physics_motor.input_direction.x
	var target_angle := head_target_marker.rotation.y + PI/2 + strafe_amount * PI/4
	var rotation_speed_multiplier := 0.02
	var rotation_speed : float = clamp(rigid_body.linear_velocity.length() * rotation_speed_multiplier, 0.0, 0.9)
	torso.rotation.y = lerp_angle(torso.rotation.y, target_angle, rotation_speed)


func look_at_direction(direction: Vector3) -> void:
	# convert to Pitch and Yaw for motor
	var horizontal_dir = Vector3(direction.x, 0, direction.z).normalized()
	head_target_yaw = atan2(horizontal_dir.x, horizontal_dir.z)

	# calculate pitch
	head_target_pitch = asin(clamp(-direction.y, -1.0, 1.0))

	rotate_head()
	rotate_body_with_head()

#endregion







#region Helpers

func is_moving() -> bool:
	return rigid_body.linear_velocity.length() > 0.01


func get_head_torso_angle_difference() -> float:
	var angle := torso.global_rotation_degrees.y - head_target_marker.global_rotation_degrees.y
	angle = wrapf(angle, -180.0, 180.0) 
	angle = deg_to_rad(angle)
	return(angle)


func _get_head_pitch(relative: Vector2) -> float:
	var new_pitch := head_target_pitch - (-relative.y * look_sensitivity * vertical_sensitivity)
	var _max_pitch := deg_to_rad(max_head_pitch)
	var _min_pitch := deg_to_rad(-max_head_pitch)
	return clamp(new_pitch, _min_pitch, _max_pitch)


func _get_next_yaw(relative: Vector2) -> float:
	return wrapf(head_target_yaw - (relative.x * look_sensitivity), -PI, PI)


func _set_shadow_quality(new_shadow_quality : ShadowQuality) -> void:
	shadow_type = new_shadow_quality
	
	if shadow:
		shadow.queue_free()
	
	if shadow_type == ShadowQuality.SIMPLE:
		assert(shadow_simple_scene != null, "ERROR: No shadow_simple_scene assigned")
		
		shadow = shadow_simple_scene.instantiate()
		shadow.position.y = shadow_simple_y_offset
		add_child(shadow)
	
	if shadow_type == ShadowQuality.DECAL:
		assert(shadow_decal_scene != null, "ERROR: No shadow_decal_scene assigned")
		
		shadow = shadow_decal_scene.instantiate()
		shadow.position.y = shadow_decal_y_offset
		add_child(shadow)


func has_move_input() -> bool:
	return input_direction.x != 0 or input_direction.y != 0


#endregion
