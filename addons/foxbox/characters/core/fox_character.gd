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
signal entered_air
signal started_sprinting
signal stopped_sprinting
signal character_model_changed(visible : bool)

#endregion







#region Exports

@export_group("Components")
@export var _physics_body : CharacterBody3D
@export var _ground_motor: FoxAdvancedCharacterMotor3D
@export var _model : FoxCharacterModel
@export var _camera_pivot : FoxCharacterCameraPivot
@export var _head_clearance_sensor : ShapeCast3D
@export var _hitbox : FoxCharacterHitbox
@export var _ground_cast : RayCast3D
@export var _state_machine : FoxCharacterStateMachine


@export_group("Movement Settings")
@export var walk_speed : float = 5.0
@export var crouch_speed : float = 2.0
@export var sprint_speed : float = 10.0
@export var max_head_pitch := 89.0
## How fast the character needs to be moving to enter air animations.
@export var enter_air_animation_velocity := 3.5
## The % the velocity needs to be of the sprint_speed for the character to stop sprinting. Default 5%.
@export var stop_sprinting_threshold := 0.05


#region Jump Parameters

@export_group("Jump Physics")
## Maximum number of jumps allowed before landing (1 = Normal, 2 = Double Jump).
@export var max_jumps: int = 1
## How long the player can still jump after walking off a ledge.
@export var coyote_duration: float = 0.15
@export var jump_buffer_time: float = 0.1
## The multiplier used for the jump force when jumping from a crouched position.
## For example, 1.2 is a 20% jump boost. 
@export var jump_crouch_multiplier := 1.2

#endregion


@export_group("Visual Optimizer")
## @experimental
## Might need refactoring, I don't know if I like the idea of the character
## being coupled to the idea of a visual optimizer. I'll have to see.
@export var visual_optimizer : FoxVisualOptimizer

#endregion







#region StateMachine stuff

var _sprint_intent: bool = false
var _crouch_intent: bool = false

var _wants_to_jump := false
var _wants_to_dash := false

func is_in_water() -> bool:
	return false

func is_flying() -> bool:
	return false

#endregion




#region Variables

var hands : FoxCharacterHands:
	get: return _model.hands
var accessories : FoxCharacterAccessories:
	get: return _model.accessories
#var current_speed : float:
#	get: return _motor.speed
#	set(new_value):
#		_motor.speed = new_value
#		current_speed = new_value

var is_free_looking := false

var input_direction := Vector2.ZERO:
	set = set_input_direction

var input_strength := 0.0:
	set(new_value):
		input_strength = clampf(new_value, 0.0, 1.0)
		#_motor.input_strength = new_value

var current_pose : Pose = Pose.STANDING : set = set_pose

enum Pose {
	STANDING,
	CROUCHING,
	IN_AIR,
}

var jumps_made: int = 0
var last_grounded_time: int = 0
var last_jump_time: int = 0

var _aim_target_pitch : float
var _max_head_pitch_rad : float
var _free_look_offset: float = 0.0
var _jump_buffer_timer: float = 0.0

#endregion







#region Virtual Methods

func _ready() -> void:
	assert(_physics_body != null, "ERROR: No _physics_body was assigned to character. "+str(get_path()))
	#assert(_motor != null, "ERROR: No _motor was assigned to character. "+str(get_path()))
	assert(_model != null, "ERROR: No _model was assigned to character. "+str(get_path()))
	assert(_camera_pivot != null, "ERROR: No _camera_pivot was assigned to character. "+str(get_path()))
	assert(_head_clearance_sensor != null, "ERROR: No _head_clearance_sensor was assigned to character. "+str(get_path()))
	assert(_hitbox != null, "ERROR: No _hitbox was assigned to character. "+str(get_path()))
	assert(_ground_cast != null, "ERROR: No _ground_cast was assigned to character. "+str(get_path()))
		
	_max_head_pitch_rad = deg_to_rad(max_head_pitch)
	
	_model.stand()
	
	_ground_motor.process_mode = Node.PROCESS_MODE_DISABLED


func _process(delta: float) -> void:	
	if visual_optimizer:
		if visual_optimizer.is_far:
			return
	
	_update_character_model()
	_update_freecam()
	_update_jump_request(delta)

"""
func _physics_process(_delta: float) -> void:
	if is_sprinting():
		_update_sprint()
"""
#endregion






#region Poses

## Returns true if the pose was successfully changed.
func set_pose(new_pose: Pose) -> bool:
	# 1. Guard against spam
	if new_pose == current_pose: 
		return false
	
	# 2. Guard against illegal physical states
	if new_pose == Pose.STANDING and not can_stand_up():
		return false
	
	# 3. Apply the change
	var old_pose: Pose = current_pose
	current_pose = new_pose
	
	_update_pose()
	pose_changed.emit(new_pose, old_pose)
	
	return true


func is_crouching() -> bool:
	return current_pose == Pose.CROUCHING


func is_standing() -> bool:
	return current_pose == Pose.STANDING


func stand() -> void:
	set_pose(Pose.STANDING)


func crouch() -> void:
	set_pose(Pose.CROUCHING)


func enter_air() -> void:
	set_pose(Pose.IN_AIR)


## Returns true if there is enough physical room above the character's head to stand up.
func can_stand_up() -> bool:
	_head_clearance_sensor.target_position = Vector3.ZERO
	_head_clearance_sensor.force_shapecast_update()
	return not _head_clearance_sensor.is_colliding()


func _update_pose() -> void:
	match current_pose:
		Pose.STANDING:
			_model.stand()
			_hitbox.stand()
			_camera_pivot.stand()
			stood.emit()
			
		Pose.CROUCHING:
			_model.crouch()
			_hitbox.crouch()
			_camera_pivot.crouch()
			crouched.emit()
		
		Pose.IN_AIR:
			_model.enter_air()
			_hitbox.stand()
			_camera_pivot.stand()
			entered_air.emit()

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
	#_motor.input_direction = new_value_normalized
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






#region Helpers

func get_speed_percent() -> float:
	var horizontal_speed := get_horizontal_velocity()
		
	match current_pose:
		Pose.STANDING, Pose.IN_AIR:
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


func is_on_floor() -> bool:
	return _physics_body.is_on_floor()

func has_move_input() -> bool:
	return input_direction.x != 0 or input_direction.y != 0


func is_moving_fast_vertically() -> bool:
	return abs(_physics_body.velocity.y) > enter_air_animation_velocity


func is_in_air() -> bool:
	if _ground_cast:
		_ground_cast.force_raycast_update()
		
		if _ground_cast.is_colliding():
			return false
			
	if _physics_body.is_on_floor():
		return false
		
	return true


func can_dash() -> bool:
	var dash_state = _state_machine.get_state(&"Dash")
	if dash_state and dash_state is FoxCharacterDashState:
		return dash_state.is_cooldown_finished()
	return false


func _update_character_model():
	_model.update_strafe(input_direction)
	
	if not is_free_looking: 
		_model.pitch = _aim_target_pitch
		
	_model.yaw = get_aim_torso_angle_difference()


func update_locomotion_visuals() -> void:
	print(get_speed_percent())
	_model.set_move_speed(snappedf(get_speed_percent(), 0.1))
	_model.set_vertical_speed(_physics_body.velocity.y)


func force_update_pose() -> void:
	_update_pose()


func can_jump() -> bool:
	var elapsed_seconds: float = (Time.get_ticks_msec() - last_jump_time) / 1000.0
	return elapsed_seconds > 0.15


func reset_jumps_made() -> void:
	jumps_made = 0


## Reads the dash request, checks if physically possible, and clears the buffer.
func consume_dash_request() -> void:
	_wants_to_dash = false

func consume_jump_request() -> void:
	_wants_to_jump = false
	jumps_made += 1
	last_jump_time = Time.get_ticks_msec()


func update_grounded_time() -> void:
	last_grounded_time = Time.get_ticks_msec()




func request_jump() -> void:
	_wants_to_jump = true
	_jump_buffer_timer = jump_buffer_time # Start the countdown


# Automatically forget the jump if the time runs out
func _update_jump_request(delta: float) -> void:
	if _wants_to_jump:
		_jump_buffer_timer -= delta
		if _jump_buffer_timer <= 0.0:
			cancel_jump_request()

func cancel_jump_request() -> void:
	_wants_to_jump = false

func request_dash() -> void:
	_wants_to_dash = true

func cancel_dash_request() -> void:
	_wants_to_dash = false



func set_sprint_intent(active: bool) -> void:
	_sprint_intent = active

func toggle_sprint_intent() -> void:
	_sprint_intent = !_sprint_intent

func set_crouch_intent(active: bool) -> void:
	_crouch_intent = active



func has_jump_request() -> bool:
	return _wants_to_jump

func has_dash_request() -> bool:
	return _wants_to_dash




func has_crouch_intent() -> bool:
	return _crouch_intent

func has_sprint_intent() -> bool:
	return _sprint_intent

func cancel_sprint_request() -> void:
	_sprint_intent = false

## Checks if the character has slowed down enough to break out of a sprint.
func is_below_sprint_dropoff() -> bool:
	var threshold: float = sprint_speed * stop_sprinting_threshold
	return get_current_velocity() < threshold



func is_currently_sprinting() -> bool:
	# Check if our current speed target matches our sprint speed
	return _ground_motor.speed == sprint_speed



## Checks if the character is falling but still within the grace period to jump.
func can_coyote_jump() -> bool:
	if jumps_made > 0:
		return false
		
	var time_since_ground: float = (Time.get_ticks_msec() - last_grounded_time) / 1000.0
	return time_since_ground <= coyote_duration

## Checks if the character has multi-jump charges remaining.
func can_multi_jump() -> bool:
	return jumps_made < max_jumps

#endregion
