extends TateNode3D
class_name TateCharacter
# A big bowl of spaghetti...
## something something description here







#region Signals

signal pose_changed(new_pose : Pose, old_pose : Pose)

## I probably need more signals here...

#endregion







#region Exports

@export_group("Components")
@export var physics_body : CharacterBody3D
@export var motor: TateAdvancedCharacterMotor3D
@export var visuals_pivot : Node3D
@export var character_model : TateCharacterModel
@export var camera_pivot : TateCharacterCameraPivot
@export var view_model_container : SubViewportContainer
@export var head_clearance_sensor : ShapeCast3D
@export var character_hitbox : TateCharacterHitbox
@export var ground_cast : RayCast3D

@export_group("Movement Settings")
@export var walk_speed : float = 5.0
@export var crouch_speed : float = 2.0
@export var sprint_speed : float = 10.0
@export var max_head_pitch := 89.0
## How fast the character needs to be moving to enter air animations.
@export var enter_air_animation_velocity := 3.5

@export_group("Visual Optimizer")
## @experimental
## Might need refactoring, I don't know if I like the idea of the character
## being coupled to the idea of a visual optimizer. I'll have to see.
@export var visual_optimizer : TateVisualOptimizer

#endregion







#region Variables
 
var current_speed : float:
	get: return motor.speed
	set(new_value):
		motor.speed = new_value
		current_speed = new_value

var is_free_looking := false

var input_direction := Vector2.ZERO:
	set = set_input

var input_strength := 0.0:
	set(new_value):
		input_strength = clampf(new_value, 0.0, 1.0)
		motor.input_strength = new_value

var current_pose : Pose = Pose.STANDING : set = set_pose

enum Pose {
	STANDING,
	CROUCHING,
}

var _aim_target_pitch : float
var _max_head_pitch_rad : float
var _free_look_offset: float = 0.0

#endregion







#region Ready & Process

func _ready() -> void:
	assert(motor != null, "ERROR: No motor was assigned to character. "+str(get_path()))
	
	_max_head_pitch_rad = deg_to_rad(max_head_pitch)
	
	character_model.stand()
	
	motor.sprint_speed = sprint_speed


func _process(_delta: float) -> void:	
	if visual_optimizer:
		if visual_optimizer.is_far:
			return
	
	_update_character_model()
	_update_freecam()


#endregion







#region Multiplayer

## This might need refactoring!
## I don't know if I like the idea of the networking stuff being done
## by the character. I like how "blackbox" it is but I'll have to see
## if coupling the character to the idea of multiplayer is a good or bad
## idea.

func set_network_role(is_authority: bool) -> void:
	## SERVER
	if is_authority:
		# turn on physics & logic
		motor.process_mode = Node.PROCESS_MODE_INHERIT
		motor.jump_cast.enabled = true
		set_physics_process(true)
		

	## CLIENT
	else:
		motor.process_mode = Node.PROCESS_MODE_DISABLED
		motor.jump_cast.enabled = false
		set_physics_process(false)

#endregion







#region Poses

## Returns true if the pose was successfuly changed.
func set_pose(new_pose : Pose) -> bool:
	if new_pose == current_pose: return false
	
	if new_pose == Pose.STANDING and not can_stand_up():
		print(head_clearance_sensor.get_collider(0))
		return false
	
	var old_pose := current_pose
	current_pose = new_pose
	
	_update_pose()
	
	pose_changed.emit(new_pose,old_pose)
	
	return true


func try_to_stand() -> bool:
	if can_stand_up():
		stand()
		return true
	return false


func try_to_crouch() -> bool:
	if not is_in_air():
		crouch()
		return true
	return false


func is_crouching() -> bool:
	return current_pose == Pose.CROUCHING


func is_standing() -> bool:
	return current_pose == Pose.STANDING


func stand() -> void:
	set_pose(Pose.STANDING)


func crouch() -> void:
	stop_sprint()
	set_pose(Pose.CROUCHING)


func can_stand_up() -> bool:
	head_clearance_sensor.target_position = Vector3.ZERO
	head_clearance_sensor.force_shapecast_update()
	return not head_clearance_sensor.is_colliding()


func _update_pose() -> void:
	match current_pose:
		Pose.STANDING:
			character_model.stand()
			character_hitbox.stand()
			camera_pivot.stand()
			motor.speed = walk_speed
		Pose.CROUCHING:
			character_model.crouch()
			character_hitbox.crouch()
			camera_pivot.crouch()
			motor.speed = crouch_speed


#endregion








#region Camera & Models

func get_first_person_camera_pivot() -> Marker3D:
	if camera_pivot:
		return camera_pivot.first_person_camera_pivot
	return null


func get_shoulder_camera_pivot() -> Marker3D:
	if camera_pivot:
		return camera_pivot.shoulder_camera_pivot
	return null


func show_view_model() -> void:
	if view_model_container:
		view_model_container.show()


func hide_view_model() -> void:
	if view_model_container:
		view_model_container.hide()


func show_character_model() -> void:
	if character_model:
		character_model.show_meshes()


func hide_character_model() -> void:
	if character_model:
		character_model.hide_meshes()

func _update_freecam() -> void:
	if not is_free_looking and camera_pivot and _free_look_offset != 0.0:
		_free_look_offset = 0.0
		camera_pivot.rotation.y = _free_look_offset

#endregion







#region Main Input

func set_input(direction : Vector2) -> void:
	var new_value_normalized := direction.normalized()
	motor.input_direction = new_value_normalized
	input_direction = new_value_normalized


func rotate_head_relative(relative: Vector2) -> void:
	_process_pitch(relative.y)
	_process_yaw(relative.x)


func try_to_jump() -> bool:
	if not can_stand_up():
		return false
	
	if motor.can_jump():
		if current_pose == Pose.CROUCHING:
			motor.jump(1.2)
		else:
			motor.jump()
		
		
		stand()
		return true
		
	return false


func reset_jump() -> void:
	motor.reset_jump()


func try_to_sprint() -> bool:
	if not is_sprinting() and not is_in_air():
		stand()
		motor.start_sprinting()
		return true
	return false


func stop_sprint() -> void:
	motor.is_sprinting = false


func is_sprinting() -> bool:
	return motor.is_sprinting

#endregion







#region Aim Pitch & Yaw

func _process_pitch(relative_y: float) -> void:
	_aim_target_pitch = clamp(_aim_target_pitch - relative_y, -_max_head_pitch_rad, _max_head_pitch_rad)

	if camera_pivot:
		camera_pivot.rotation.x = _aim_target_pitch


func _process_yaw(relative_x: float) -> void:
	if is_free_looking:
		_free_look_offset += -relative_x
		
		if camera_pivot:
			camera_pivot.rotation.y = _free_look_offset
			
	else:
		self.rotate_y(-relative_x)

#endregion







#region Helpers

func get_speed_percent() -> float:
	var horizontal_speed := get_horizontal_velocity()
	
	match current_pose:
		Pose.STANDING:
			return horizontal_speed / sprint_speed
		Pose.CROUCHING:
			return horizontal_speed / crouch_speed
	
	
	return 0.0


func get_horizontal_velocity() -> float:
	return Vector3(physics_body.velocity.x, 0.0, physics_body.velocity.z).length()


func get_current_velocity() -> float:
	return physics_body.velocity.length()


func is_moving() -> bool:
	return physics_body.velocity.length() > 0.01


func get_aim_torso_angle_difference() -> float:
	var angle := character_model.global_rotation.y - self.global_rotation.y
	# Between -180 and +180
	angle = wrapf(angle, -PI, PI) 
	angle = angle
	return(-angle)


func has_move_input() -> bool:
	return input_direction.x != 0 or input_direction.y != 0


func _update_character_model():
	character_model.update_strafe(input_direction)#, get_horizontal_velocity())
	
	if not is_free_looking: character_model.pitch = _aim_target_pitch
	
	character_model.yaw = get_aim_torso_angle_difference()
	character_model.set_move_speed(get_speed_percent())
	character_model.set_vertical_speed(physics_body.velocity.y)

	if is_in_air() and is_moving_fast_vertically():
		character_model.enter_air()
	elif not is_in_air():
		_update_pose()


func is_moving_fast_vertically() -> bool:
	return abs(physics_body.velocity.y) > enter_air_animation_velocity


func is_in_air() -> bool:	
	if not ground_cast.is_colliding():
		if not physics_body.is_on_floor():
			return true
	
	return false

#endregion
