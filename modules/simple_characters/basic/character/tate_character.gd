extends TateNode3D
class_name TateCharacter
# A big bowl of spaghetti...
## something something description here







#region Signals

signal pose_changed(new_pose : Pose, old_pose : Pose)
signal jumped(strength : float)
signal landed
signal item_equipped(item : Node)
signal crouched
signal stood
signal started_sprinting
signal stopped_sprinting
signal view_model_changed(visible : bool)
signal character_model_changed(visible : bool)

## I probably need more signals here...

#endregion







#region Exports

@export_group("Components")
@export var physics_body : CharacterBody3D
@export var motor: TateAdvancedCharacterMotor3D
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
## The multiplier used for the jump force when jumping from a crouched position.
## For example, 1.2 is a 20% jump boost. 
@export var jump_crouch_multiplier := 1.2
## How fast the character needs to be moving to enter air animations.
@export var enter_air_animation_velocity := 3.5

@export_group("Visual Optimizer")
## @experimental
## Might need refactoring, I don't know if I like the idea of the character
## being coupled to the idea of a visual optimizer. I'll have to see.
@export var visual_optimizer : TateVisualOptimizer

#endregion







#region Variables

var character_hands : TateCharacterHands:
	get: return character_model.character_hands
var current_speed : float:
	get: return motor.speed
	set(new_value):
		motor.speed = new_value
		current_speed = new_value

var is_free_looking := false

var input_direction := Vector2.ZERO:
	set = set_input_direction

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
var _was_in_air := false

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
		#motor.jump_cast.enabled = true
		set_physics_process(true)
		

	## CLIENT
	else:
		motor.process_mode = Node.PROCESS_MODE_DISABLED
		#motor.jump_cast.enabled = false
		set_physics_process(false)

#endregion







#region Motor Control

func disable_motor() -> void:
	motor.disable()
	

func enable_motor() -> void:
	motor.enable()

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
			stood.emit()
		Pose.CROUCHING:
			character_model.crouch()
			character_hitbox.crouch()
			camera_pivot.crouch()
			motor.speed = crouch_speed
			crouched.emit()

#endregion







#region Hands Interface

func empty_hands() -> void:
	character_hands.empty_hands()


func empty_right_hand() -> void:
	character_hands.empty_right_hand()


func empty_left_hand() -> void:
	character_hands.empty_left_hand() 


func hold_node(node : Node, left_handed := false) -> bool:
	return character_hands.hold_node(node, left_handed)


func hold_item(item : TateHoldableItem, left_handed := false):
	character_hands.hold_item(item, left_handed)
	item_equipped.emit(item)


func left_hand_has_item() -> bool:
	return character_hands.left_hand_has_node()


func right_hand_has_item() -> bool:
	return character_hands.right_hand_has_node()


func get_right_hand_item() -> Node:
	return character_hands.get_right_hand_node()


func get_left_hand_item() -> Node:
	return character_hands.get_left_hand_node()


func enable_right_hand_ik(target_node : Node3D, pole_node : Node3D) -> void:
	character_hands.enable_right_hand_ik(target_node, pole_node)


func disable_right_hand_ik() -> void:
	character_hands.disable_right_hand_ik()


func enable_left_hand_ik(target_node : Node3D, pole_node : Node3D) -> void:
	character_hands.enable_left_hand_ik(target_node, pole_node)


func disable_left_hand_ik() -> void:
	character_hands.disable_left_hand_ik()

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
		view_model_changed.emit(true)


func hide_view_model() -> void:
	if view_model_container:
		view_model_container.hide()
		view_model_changed.emit(false)


func show_character_model() -> void:
	if character_model:
		character_model.show_meshes()
		character_model_changed.emit(true)


func hide_character_model() -> void:
	if character_model:
		character_model.hide_meshes()
		character_model_changed.emit(false)


func _update_freecam() -> void:
	if not is_free_looking and camera_pivot and _free_look_offset != 0.0:
		_free_look_offset = 0.0
		camera_pivot.rotation.y = _free_look_offset

#endregion







#region Main Input

func set_input_direction(direction : Vector2) -> void:
	var new_value_normalized := direction.normalized()
	motor.input_direction = new_value_normalized
	input_direction = new_value_normalized


func look_at_position(target_global_pos: Vector3) -> void:
	# 1. Calculate the direction vector
	var direction = target_global_pos - self.global_position
	
	# Safety check to prevent math errors (looking at self)
	if direction.length_squared() < 0.001: return

	# 2. YAW (Body Rotation)
	# We use atan2 to get the angle on the flat ground plane (X, Z).
	# Godot's forward is -Z, so we calculate the angle offset from that.
	var target_yaw = atan2(-direction.x, -direction.z)
	
	# Apply directly to the root node (The Body)
	self.global_rotation.y = target_yaw
	
	# 3. PITCH (Head/Spine Rotation)
	# We calculate the angle difference in height vs distance
	var flat_distance = Vector2(direction.x, direction.z).length()
	var target_pitch = atan2(direction.y, flat_distance)
	
	# Clamp it so the AI doesn't snap its neck looking straight up/down
	_aim_target_pitch = clamp(target_pitch, -_max_head_pitch_rad, _max_head_pitch_rad)
	
	# Apply to camera pivot (which drives the Spine/Head via the Model script)
	if camera_pivot:
		camera_pivot.rotation.x = _aim_target_pitch
		
	# Update the model immediately so there's no visual lag frame
	character_model.pitch = _aim_target_pitch


## Rotates the character to look at a target smoothly.
## @turn_speed: How fast to rotate (radians per second). Try 5.0 to 10.0.
func look_at_position_smooth(target_global_pos: Vector3, delta: float, turn_speed: float = 8.0) -> void:
	var direction = target_global_pos - self.global_position
	
	# 1. THE GLITCH FIX (Deadzone)
	# If the target is too close horizontally (standing on head), don't spin the body.
	var flat_distance = Vector2(direction.x, direction.z).length()
	if flat_distance < 0.5: 
		return

	# 2. YAW (Body Rotation)
	var target_yaw = atan2(-direction.x, -direction.z)
	# use lerp_angle to prevent spinning 360 degrees unnecessarily
	self.rotation.y = lerp_angle(self.rotation.y, target_yaw, turn_speed * delta)
	
	# 3. PITCH (Head/Spine Rotation)
	var target_pitch = atan2(direction.y, flat_distance)
	target_pitch = clamp(target_pitch, -_max_head_pitch_rad, _max_head_pitch_rad)
	
	# We lerp the pitch variable, then apply it to the camera/model
	_aim_target_pitch = lerp_angle(_aim_target_pitch, target_pitch, turn_speed * delta)
	
	if camera_pivot:
		camera_pivot.rotation.x = _aim_target_pitch
	
	# Update model immediately for smooth visuals
	character_model.pitch = _aim_target_pitch


func rotate_head_relative(relative: Vector2) -> void:
	_process_pitch(relative.y)
	_process_yaw(relative.x)


func try_to_jump() -> bool:
	if not can_stand_up():
		return false
	
	if motor.can_jump():
		if current_pose == Pose.CROUCHING:
			motor.jump(jump_crouch_multiplier)
			jumped.emit(jump_crouch_multiplier)
		else:
			motor.jump()
			jumped.emit(1.0)
		
		
		stand()
		return true
		
	return false


func reset_jump_pressed() -> void:
	motor.reset_jump_pressed()


func try_to_sprint() -> bool:
	if not is_sprinting() and not is_in_air():
		stand()
		motor.start_sprinting()
		started_sprinting.emit()
		return true
	return false


func stop_sprint() -> void:
	motor.is_sprinting = false
	stopped_sprinting.emit()


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
		_was_in_air = true
	elif not is_in_air() and _was_in_air:
		_update_pose()
		_was_in_air = false
		landed.emit()


func is_moving_fast_vertically() -> bool:
	return abs(physics_body.velocity.y) > enter_air_animation_velocity


func is_in_air() -> bool:	
	if not ground_cast.is_colliding():
		if not physics_body.is_on_floor():
			return true
	
	return false

#endregion
