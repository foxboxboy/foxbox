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

signal jumped(strength : float)
signal dashed
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
@export var jump: FoxJumpManager
@export var dash: FoxDashManager
@export var pose: FoxCharacterPoseManager
@export var sprint: FoxSprintManager

@export var _physics_body : CharacterBody3D
@export var _ground_motor: FoxAdvancedCharacterMotor3D
@export var model : FoxCharacterModel
@export var _camera_pivot : FoxCharacterCameraPivot
#@export var _head_clearance_sensor : ShapeCast3D
@export var _hitbox : FoxCharacterHitbox
@export var _ground_cast : RayCast3D
@export var _state_machine : FoxCharacterStateMachine


@export_group("Movement Settings")
@export var walk_speed : float = 5.0
@export var max_head_pitch := 89.0
## How fast the character needs to be moving to enter air animations.
@export var enter_air_animation_velocity := 3.5
## The % the velocity needs to be of the sprint_speed for the character to stop sprinting. Default 5%.
@export var stop_sprinting_threshold := 0.05

#endregion


@export_group("Visual Optimizer")
## @experimental
## Might need refactoring, I don't know if I like the idea of the character
## being coupled to the idea of a visual optimizer. I'll have to see.
@export var visual_optimizer : FoxVisualOptimizer

#endregion







#region Variables

# === Input Intents ===
var input_direction := Vector2.ZERO:
	set = set_input_direction

var input_strength := 0.0:
	set(new_value):
		input_strength = clampf(new_value, 0.0, 1.0)

# IDK ABOUT THIS is_free_looking maybe make it more in line with the other inputs?
var is_free_looking := false
# === === === ===


# === Camera Memory ===
var _aim_target_pitch : float
var _max_head_pitch_rad : float
var _free_look_offset: float = 0.0
# === === === ===


#endregion





#region Virtual Methods

func _ready() -> void:
	assert(_physics_body != null, "ERROR: No _physics_body was assigned to character. "+str(get_path()))
	assert(_ground_motor != null, "ERROR: No _ground_motor was assigned to character. "+str(get_path()))
	assert(model != null, "ERROR: No model was assigned to character. "+str(get_path()))
	assert(_camera_pivot != null, "ERROR: No _camera_pivot was assigned to character. "+str(get_path()))
	#assert(_head_clearance_sensor != null, "ERROR: No _head_clearance_sensor was assigned to character. "+str(get_path()))
	assert(_hitbox != null, "ERROR: No _hitbox was assigned to character. "+str(get_path()))
	assert(_ground_cast != null, "ERROR: No _ground_cast was assigned to character. "+str(get_path()))
		
	_max_head_pitch_rad = deg_to_rad(max_head_pitch)
	
	model.stand()
	
	_ground_motor.process_mode = Node.PROCESS_MODE_DISABLED
	
	if pose:
		pose.pose_changed.connect(_on_pose_changed)


func _process(delta: float) -> void:	
	if visual_optimizer:
		if visual_optimizer.is_far:
			return
	
	_update_character_model()
	_update_freecam()

#endregion






#region Pose

## Acts as a mediator, syncing the visual model, collision hitbox, and camera 
## pivot to whatever physical pose the manager decided was valid.
func _on_pose_changed(new_pose: FoxCharacterPoseManager.Type, _old_pose: FoxCharacterPoseManager.Type) -> void:
	match new_pose:
		pose.Type.STANDING:
			model.stand()
			_hitbox.stand()
			_camera_pivot.stand()
			stood.emit()
			
		pose.Type.CROUCHING:
			model.crouch()
			_hitbox.crouch()
			_camera_pivot.crouch()
			crouched.emit()
			
		pose.Type.IN_AIR:
			model.enter_air()
			_hitbox.stand() # Collision stays tall in the air
			_camera_pivot.stand()
			entered_air.emit()
			
		pose.Type.PRONE:
			# Call _model.prone(), _hitbox.prone() when you build them!
			pass
			
		pose.Type.SWIMMING:
			# Call _model.swim(), _hitbox.prone()
			pass

#endregion





#region Visuals

func update_locomotion_visuals() -> void:
	model.set_move_speed(snappedf(get_speed_percent(), 0.1))
	model.set_vertical_speed(_physics_body.velocity.y)

#endregion





#region Camera

func get_first_person_camera_pivot() -> Marker3D:
	if _camera_pivot:
		return _camera_pivot.first_person_camera_pivot
	return null


func get_shoulder_camera_pivot() -> Marker3D:
	if _camera_pivot:
		return _camera_pivot.shoulder_camera_pivot
	return null


func _update_freecam() -> void:
	if not is_free_looking and _camera_pivot and _free_look_offset != 0.0:
		_free_look_offset = 0.0
		_camera_pivot.rotation.y = _free_look_offset

#endregion






#region Aim

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
		
	model.pitch = _aim_target_pitch



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
	
	model.pitch = _aim_target_pitch


func rotate_head_relative(relative: Vector2) -> void:
	_process_pitch(relative.y)
	_process_yaw(relative.x)


#endregion





#region Input Routing

# === Main Direction ===
func set_input_direction(direction : Vector2) -> void:
	var new_value_normalized := direction.normalized()
	input_direction = new_value_normalized
# === === === ===

#endregion





#region Kinematic Queries

### === Pose ===

func is_standing() -> bool:
	return pose.current_pose == pose.Type.STANDING

func is_crouching() -> bool:
	return pose.current_pose == pose.Type.CROUCHING

func is_flying() -> bool:
	return false

### === === === === ###


### === Where === ###

func is_on_floor() -> bool:
	return _physics_body.is_on_floor()

func is_in_water() -> bool:
	return false

func is_in_air() -> bool:
	if _ground_cast:
		_ground_cast.force_raycast_update()
		
		if _ground_cast.is_colliding():
			return false
			
	if _physics_body.is_on_floor():
		return false
		
	return true
	
### === === === === ###



### === Speed & Velocity === ###

func is_moving() -> bool:
	return _physics_body.velocity.length() > 0.01

func get_horizontal_velocity() -> float:
	return Vector3(_physics_body.velocity.x, 0.0, _physics_body.velocity.z).length()

func get_current_velocity() -> float:
	return _physics_body.velocity.length()

func get_speed_percent() -> float:
	if not pose: 
		return 0.0
		
	var horizontal_speed := get_horizontal_velocity()
	
	match pose.current_pose:
		pose.Type.STANDING, pose.Type.IN_AIR:
			# If a sprint manager exists, use its speed as the 100% maximum.
			# Otherwise, fall back to the standard walking speed.
			var max_speed: float = sprint.speed if sprint else pose.walk_speed
			return horizontal_speed / max_speed
			
		pose.Type.CROUCHING:
			return horizontal_speed / pose.crouch_speed
			
		pose.Type.PRONE, pose.Type.SWIMMING, pose.Type.GLIDING:
			return horizontal_speed / pose.prone_speed
			
		pose.Type.SITTING:
			return 0.0
	
	return 0.0


func is_moving_fast_vertically() -> bool:
	return abs(_physics_body.velocity.y) > enter_air_animation_velocity

### === === === === ###


### === Has Kinematic Input ===

func has_move_input() -> bool:
	return input_direction.x != 0 or input_direction.y != 0

### === === === === ###

#endregion




#region Internal Helpers

func _update_character_model():
	model.update_strafe(input_direction)
	
	if not is_free_looking: 
		model.pitch = _aim_target_pitch
		
	model.yaw = _get_aim_torso_angle_difference()


func _get_aim_torso_angle_difference() -> float:
	var angle := model.global_rotation.y - self.global_rotation.y
	# Between -180 and +180
	angle = wrapf(angle, -PI, PI) 
	angle = angle
	return(-angle)


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
