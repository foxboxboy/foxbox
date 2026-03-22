extends FoxNode3D
class_name FoxCharacter

## A high-level facade abstraction for a humanoid character that handles physics, 
## animation, and interaction delegation.
##
## Designed to be controlled by an outside controller. This class acts as the "muscle"
## rather than the "brain", blindly executing inputs and routing data between 
## specialized components (State Machine, Pose Manager, Motors).
##
## [br] [br]
## ([b]WARNING[/b] this feature below is deprcated)
## [br]
## [b]Note:[/b] If a [FoxVisualOptimizer] is assigned and the character is far away, 
## visual processing and aim math are suspended to save performance.

#region Signals

signal jumped(strength: float)
signal dashed
signal landed
signal proned
signal crouched
signal stood
signal entered_air
signal started_sprinting
signal stopped_sprinting
signal character_model_changed(visible: bool)

#endregion





#region Exports

@export_group("Components")
@export var jump: FoxJumpManager
@export var dash: FoxDashManager
@export var pose: FoxCharacterPoseManager
@export var sprint: FoxSprintManager
@export var aim: FoxCharacterAimManager

@export var _physics_body: CharacterBody3D
@export var _ground_motor: FoxAdvancedCharacterMotor3D
@export var model: FoxCharacterModel
@export var _hitbox: FoxCharacterHitbox
@export var _ground_cast: RayCast3D
@export var _state_machine: FoxCharacterStateMachine

@export_group("Movement Settings")
@export var walk_speed: float = 5.0
@export var max_head_pitch := 89.0
## Velocity required to trigger aerial blend animations.
@export var enter_air_animation_velocity := 3.5
## Velocity ratio (relative to sprint speed) required to maintain a sprint.
@export var stop_sprinting_threshold := 0.05

#@export_group("Visual Optimizer")
## Suspends [method _process] visual and aim updates when the character is distant.
#@export var visual_optimizer: FoxVisualOptimizer

#endregion





#region Variables

## The raw normalized directional input intent (usually from a joystick or WASD).
var input_direction := Vector2.ZERO: set = set_input_direction

## The magnitude of the input intent (0.0 to 1.0).
var input_strength := 0.0:
	set(new_value):
		input_strength = clampf(new_value, 0.0, 1.0)

#endregion





#region Virtual Methods

func _ready() -> void:
	assert(_physics_body != null, "FoxCharacter missing _physics_body on %s" % get_path())
	assert(_ground_motor != null, "FoxCharacter missing _ground_motor on %s" % get_path())
	assert(model != null, "FoxCharacter missing model on %s" % get_path())
	assert(aim != null, "FoxCharacter missing aim on %s" % get_path())
	assert(_hitbox != null, "FoxCharacter missing _hitbox on %s" % get_path())
	assert(_ground_cast != null, "FoxCharacter missing _ground_cast on %s" % get_path())
		
	model.stand()
	_ground_motor.process_mode = Node.PROCESS_MODE_DISABLED
	
	if pose:
		pose.pose_changed.connect(_on_pose_changed)


func _process(delta: float) -> void:    
	#if visual_optimizer and visual_optimizer.is_far:
	#	return
	
	_update_character_model()

#endregion





#region Pose

func _on_pose_changed(new_pose: FoxCharacterPoseManager.Type, _old_pose: FoxCharacterPoseManager.Type) -> void:
	match new_pose:
		pose.Type.STANDING:
			model.stand()
			_hitbox.stand()
			aim.stand()
			stood.emit()
			
		pose.Type.CROUCHING:
			model.crouch()
			_hitbox.crouch()
			aim.crouch()
			crouched.emit()
			
		pose.Type.IN_AIR:
			model.enter_air()
			_hitbox.stand() 
			aim.stand()
			entered_air.emit()
			
		pose.Type.PRONE:
			model.prone()
			_hitbox.prone()
			aim.prone()
			proned.emit()
			
		pose.Type.SWIMMING:
			pass

#endregion





#region Visuals

## Feeds the physical velocity data into the visual model's animation tree.
func update_locomotion_visuals() -> void:
	model.set_move_speed(snappedf(get_speed_percent(), 0.1))
	model.set_vertical_speed(_physics_body.velocity.y)

#endregion





#region Input Routing

func set_input_direction(direction: Vector2) -> void:
	input_direction = direction.normalized()


## Clears any momentary action intents (Jump, Dash) to prevent input ghosting.
## Note: This deliberately does NOT clear persistent stances like Crouch or Sprint.
func flush_inputs() -> void:
	if dash:
		dash.cancel()
	if jump:
		jump.cancel()

#endregion





#region Kinematic Queries

func is_flying() -> bool:
	return false

func is_on_floor() -> bool:
	return _physics_body.is_on_floor()

func is_in_water() -> bool:
	return false

## Verifies aerial state via the physics body floor normal, corroborated by the ground cast.
func is_in_air() -> bool:
	if _ground_cast:
		_ground_cast.force_raycast_update()
		if _ground_cast.is_colliding():
			return false
			
	return not _physics_body.is_on_floor()


func is_moving() -> bool:
	return _physics_body.velocity.length() > 0.01

func get_horizontal_velocity() -> float:
	return Vector3(_physics_body.velocity.x, 0.0, _physics_body.velocity.z).length()

func get_current_velocity() -> float:
	return _physics_body.velocity.length()


## Calculates the normalized speed ratio relative to the current state's max speed.
func get_speed_percent() -> float:
	var horizontal_speed := get_horizontal_velocity()
	
	match pose.current_pose:
		pose.Type.STANDING, pose.Type.IN_AIR:
			var max_speed: float = sprint.speed
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

func has_move_input() -> bool:
	return input_direction.x != 0 or input_direction.y != 0

#endregion





#region Internal Helpers

func _update_character_model() -> void:
	model.update_strafe(input_direction)
	
	# Ask the camera component for its data!
	if aim and not aim.is_free_looking: 
		model.pitch = aim.get_pitch()
		
	model.yaw = _get_aim_torso_angle_difference()


func _get_aim_torso_angle_difference() -> float:
	var angle := model.global_rotation.y - self.global_rotation.y
	angle = wrapf(angle, -PI, PI) 
	return -angle

#endregion
