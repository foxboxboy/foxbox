extends FoxNode3D
class_name FoxCharacter
## A "pawn" or "puppet". A high level facade abstraction for a humanoid character 
## that handles physics, animation, and interaction.
##
## Designed to be controlled by an outside controller. This class is designed to 
## only handle the body and nothing more. It falls into the category of "muscle" 
## rather than brain.
##
## [br] [br]
## [b]Responsibilities:[/b]
## [br] - Move a character around.
## [br] - Animate it.
## [br] - Make it hold nodes or FoxHoldableItems.
##
## [br] [br]
## [b]What this class does NOT do:[/b]
## [br] - It does not know how to receive input.
## [br] - It does not know game rules.
## [br] - It does not manage inventory (outside its two hands).
## [br] - It does not handle first person view models.
##
## [br] [br]
## [b]Note:[/b]
## Most behaviour in this are delegated as components. If you need less abstraction 
## and more control, you can assemble the components into your own character controller.




#region Signals

signal pose_changed(new_pose : Pose, old_pose : Pose)
signal jumped(strength : float)
signal landed
signal crouched
signal stood
signal started_sprinting
signal stopped_sprinting
signal character_model_changed(visible : bool)

#endregion







#region Exports

@export_group("Components")
@export var _physics_body : CharacterBody3D
@export var _motor: FoxAdvancedCharacterMotor3D
@export var _model : FoxCharacterModel
@export var _camera_pivot : FoxCharacterCameraPivot
@export var _head_clearance_sensor : ShapeCast3D
@export var _character_hitbox : FoxCharacterHitbox
@export var _ground_cast : RayCast3D

@export_group("Movement Settings")
@export var walk_speed : float = 5.0
@export var crouch_speed : float = 2.0
@export var sprint_speed : float = 10.0
@export var max_head_pitch := 89.0
## The multiplier used for the jump force when jumping from a crouched position.
## For example, 1.2 is a 20% jump boost. 
@export var jump_crouch_multiplier := 1.2
## How fast the character needs to be moving to enter air animations.
@export var enter_air_animation_velocity := 3.5
## The % the velocity needs to be of the sprint_speed for the character to stop sprinting. Default 5%.
@export var stop_sprinting_threshold := 0.05

@export_group("Visual Optimizer")
## @experimental
## Might need refactoring, I don't know if I like the idea of the character
## being coupled to the idea of a visual optimizer. I'll have to see.
@export var visual_optimizer : FoxVisualOptimizer

#endregion







#region Variables

var hands : FoxCharacterHands:
	get: return _model.hands
var current_speed : float:
	get: return _motor.speed
	set(new_value):
		_motor.speed = new_value
		current_speed = new_value

var is_free_looking := false

var input_direction := Vector2.ZERO:
	set = set_input_direction

var input_strength := 0.0:
	set(new_value):
		input_strength = clampf(new_value, 0.0, 1.0)
		_motor.input_strength = new_value

var current_pose : Pose = Pose.STANDING : set = set_pose

enum Pose {
	STANDING,
	CROUCHING,
}

var _aim_target_pitch : float
var _max_head_pitch_rad : float
var _free_look_offset: float = 0.0
var _was_in_air := false
var _is_sprinting := false

#endregion







#region Virtual Methods

func _ready() -> void:
	assert(_physics_body != null, "ERROR: No _physics_body was assigned to character. "+str(get_path()))
	assert(_motor != null, "ERROR: No _motor was assigned to character. "+str(get_path()))
	assert(_model != null, "ERROR: No _model was assigned to character. "+str(get_path()))
	assert(_camera_pivot != null, "ERROR: No _camera_pivot was assigned to character. "+str(get_path()))
	assert(_head_clearance_sensor != null, "ERROR: No _head_clearance_sensor was assigned to character. "+str(get_path()))
	assert(_character_hitbox != null, "ERROR: No _character_hitbox was assigned to character. "+str(get_path()))
	assert(_ground_cast != null, "ERROR: No _ground_cast was assigned to character. "+str(get_path()))
		
	_max_head_pitch_rad = deg_to_rad(max_head_pitch)
	
	_model.stand()
	
	_motor.speed = walk_speed


func _process(_delta: float) -> void:	
	if visual_optimizer:
		if visual_optimizer.is_far:
			return
	
	_update_character_model()
	_update_freecam()


func _physics_process(_delta: float) -> void:
	if is_sprinting():
		_update_sprint()

#endregion







#region Motor Control

func disable__motor() -> void:
	_motor.disable()
	

func enable__motor() -> void:
	_motor.enable()

#endregion







#region Poses

## Returns true if the pose was successfuly changed.
func set_pose(new_pose : Pose) -> bool:
	if new_pose == current_pose: return false
	
	if new_pose == Pose.STANDING and not can_stand_up():
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
	_head_clearance_sensor.target_position = Vector3.ZERO
	_head_clearance_sensor.force_shapecast_update()
	return not _head_clearance_sensor.is_colliding()


func _update_pose() -> void:
	match current_pose:
		Pose.STANDING:
			_model.stand()
			_character_hitbox.stand()
			_camera_pivot.stand()
			
			if is_sprinting():
				_motor.speed = sprint_speed
			else:
				_motor.speed = walk_speed
			
			stood.emit()
			
		Pose.CROUCHING:
			_model.crouch()
			_character_hitbox.crouch()
			_camera_pivot.crouch()
			_motor.speed = crouch_speed
			crouched.emit()

#endregion







#region Camera & Models

func get_first_person_camera_pivot() -> Marker3D:
	if _camera_pivot:
		return _camera_pivot.first_person_camera_pivot
	return null


func get_shoulder_camera_pivot() -> Marker3D:
	if _camera_pivot:
		return _camera_pivot.shoulder_camera_pivot
	return null


func show_character_model() -> void:
	if _model:
		_model.show_meshes()
		character_model_changed.emit(true)


func hide_character_model() -> void:
	if _model:
		_model.hide_meshes()
		character_model_changed.emit(false)


func _update_freecam() -> void:
	if not is_free_looking and _camera_pivot and _free_look_offset != 0.0:
		_free_look_offset = 0.0
		_camera_pivot.rotation.y = _free_look_offset

#endregion







#region Main Input

func set_input_direction(direction : Vector2) -> void:
	var new_value_normalized := direction.normalized()
	_motor.input_direction = new_value_normalized
	input_direction = new_value_normalized

#endregion







#region Aim Rotation

func look_at_position(target_global_pos: Vector3) -> void:
	var direction = target_global_pos - self.global_position
	
	# Safety check to prevent math errors (looking at self)
	if direction.length_squared() < 0.001: return

	# Yaw
	var target_yaw = atan2(-direction.x, -direction.z)
	
	self.global_rotation.y = target_yaw
	
	# Pitch
	# We calculate the angle difference in height vs distance
	var flat_distance = Vector2(direction.x, direction.z).length()
	var target_pitch = atan2(direction.y, flat_distance)
	
	# Clamp it so we don't snap our spine looking straight up/down
	_aim_target_pitch = clamp(target_pitch, -_max_head_pitch_rad, _max_head_pitch_rad)
	
	if _camera_pivot:
		_camera_pivot.rotation.x = _aim_target_pitch
		
	_model.pitch = _aim_target_pitch



func look_at_position_smooth(target_global_pos: Vector3, delta: float, turn_speed: float = 8.0) -> void:
	var direction = target_global_pos - self.global_position
	
	# If the target is too close horizontally don't spin the body.
	var flat_distance = Vector2(direction.x, direction.z).length()
	if flat_distance < 0.5: 
		return

	# Yaw
	var target_yaw = atan2(-direction.x, -direction.z)
	self.rotation.y = lerp_angle(self.rotation.y, target_yaw, turn_speed * delta)
	
	# Pitch
	var target_pitch = atan2(direction.y, flat_distance)
	target_pitch = clamp(target_pitch, -_max_head_pitch_rad, _max_head_pitch_rad)
	
	# We lerp the pitch variable, then apply it to the camera/model
	_aim_target_pitch = lerp_angle(_aim_target_pitch, target_pitch, turn_speed * delta)
	
	if _camera_pivot:
		_camera_pivot.rotation.x = _aim_target_pitch
	
	_model.pitch = _aim_target_pitch


func rotate_head_relative(relative: Vector2) -> void:
	_process_pitch(relative.y)
	_process_yaw(relative.x)


func _process_pitch(relative_y: float) -> void:
	_aim_target_pitch = clamp(_aim_target_pitch - relative_y, -_max_head_pitch_rad, _max_head_pitch_rad)

	if _camera_pivot:
		_camera_pivot.rotation.x = _aim_target_pitch


func _process_yaw(relative_x: float) -> void:
	if is_free_looking:
		_free_look_offset += -relative_x
		
		if _camera_pivot:
			_camera_pivot.rotation.y = _free_look_offset
			
	else:
		self.rotate_y(-relative_x)

#endregion







#region Jump

func try_to_jump() -> bool:
	if not can_stand_up():
		return false
	
	if _motor.can_jump():
		if current_pose == Pose.CROUCHING:
			_motor.jump(jump_crouch_multiplier)
			jumped.emit(jump_crouch_multiplier)
		else:
			_motor.jump()
			jumped.emit(1.0)
		
		stand()
		return true
		
	return false


func reset_jump_pressed() -> void:
	_motor.reset_jump_pressed()

#endregion







#region Sprint

func try_to_sprint() -> bool:
	if not is_sprinting() and not is_in_air():
		stand()
		_motor.speed = sprint_speed
		_is_sprinting = true
		started_sprinting.emit()
		return true
	return false


func stop_sprint() -> void:
	_is_sprinting = false
	_motor.speed = walk_speed
	stopped_sprinting.emit()


func is_sprinting() -> bool:
	return _is_sprinting


func _update_sprint() -> void:
	if get_current_velocity() < sprint_speed * stop_sprinting_threshold:
		stop_sprint()

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
	return Vector3(_physics_body.velocity.x, 0.0, _physics_body.velocity.z).length()


func get_current_velocity() -> float:
	return _physics_body.velocity.length()


func is_moving() -> bool:
	return _physics_body.velocity.length() > 0.01


func get_aim_torso_angle_difference() -> float:
	var angle := _model.global_rotation.y - self.global_rotation.y
	# Between -180 and +180
	angle = wrapf(angle, -PI, PI) 
	angle = angle
	return(-angle)


func has_move_input() -> bool:
	return input_direction.x != 0 or input_direction.y != 0


func is_moving_fast_vertically() -> bool:
	return abs(_physics_body.velocity.y) > enter_air_animation_velocity


func is_in_air() -> bool:	
	if not _ground_cast.is_colliding():
		if not _physics_body.is_on_floor():
			return true
	
	return false


func _update_character_model():
	_model.update_strafe(input_direction)#, get_horizontal_velocity())
	
	if not is_free_looking: _model.pitch = _aim_target_pitch
	
	_model.yaw = get_aim_torso_angle_difference()
	
	_model.set_move_speed(snappedf(get_speed_percent(),0.1))
	_model.set_vertical_speed(_physics_body.velocity.y)

	if is_in_air() and is_moving_fast_vertically():
		_model.enter_air()
		_was_in_air = true
	elif not is_in_air() and _was_in_air:
		_update_pose()
		_was_in_air = false
		landed.emit()

#endregion
