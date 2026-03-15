class_name FoxCharacterPoseManager
extends FoxNode

## Component that manages the character's macro human configuration.
##
## Acts as the definitive source of truth for the character's physical shape 
## and visual stance. Evaluates player intents against physical constraints, 
## and allows specialized physics states to lock custom poses.

## Emitted whenever the active pose changes. The character facade should route 
## this to the visual model, collision hitbox, and camera pivot.
signal pose_changed(new_pose: Type, old_pose: Type)

## Represents the mutually exclusive macro configurations of the character.
enum Type {
	STANDING,
	CROUCHING,
	PRONE,
	IN_AIR,
	SITTING,
	SWIMMING,
	GLIDING
}

@export_group("Dependencies")
## The sensor used to detect if a ceiling blocks the character from standing.
@export var headroom_sensor: ShapeCast3D

@export_group("Speeds")
## The maximum grounded speed when the character is standing.
@export var walk_speed: float = 5.0
## The maximum grounded speed when the character is crouching.
@export var crouch_speed: float = 2.0
## The maximum grounded speed when the character is prone.
@export var prone_speed: float = 1.0


var current_pose: Type = Type.STANDING

var _is_crouch_requested: bool = false
var _is_prone_requested: bool = false

# Stores a pose forced by a specialized state (e.g., SwimState) to bypass normal evaluation.
var _locked_pose: int = -1 


## Evaluates intents and physical constraints to determine the correct locomotion pose.
## Requires the current [param is_grounded] context from the active state.
func evaluate(is_grounded: bool) -> void:
	if _locked_pose != -1:
		_set_pose(_locked_pose as Type)
		return
	
	# 1. Contextual Override (Air always forces In-Air)
	if not is_grounded:
		_set_pose(Type.IN_AIR)
		return
		
	# 2. Determine the "Desired" Pose based on player intent
	var desired_pose := Type.STANDING
	if _is_prone_requested:
		desired_pose = Type.PRONE
	elif _is_crouch_requested:
		desired_pose = Type.CROUCHING
		
	# 3. Physical Validation (The "Headroom Stack")
	var final_pose := desired_pose
	
	# If we want to be STANDING, we must be able to clear the crouch-to-stand height
	if desired_pose == Type.STANDING and not _can_physically_stand():
		final_pose = Type.CROUCHING
	
	# If we are now forced to be CROUCHING (or want to be), we check prone-to-crouch height
	# Note: Add a second sensor here if you want to support Prone -> Crouch trapping!
	
	_set_pose(final_pose)


## Registers an intent to crouch during standard locomotion.
func request_crouch() -> void:
	_is_crouch_requested = true


## Cancels a pending crouch intent.
func cancel_crouch() -> void:
	_is_crouch_requested = false


## Registers an intent to go prone during standard locomotion.
func request_prone() -> void:
	_is_prone_requested = true


## Cancels a pending prone intent.
func cancel_prone() -> void:
	_is_prone_requested = false


## Forces the manager into a specific pose, ignoring standard grounded/intent evaluation.
## Used by specialized states (Swim, Glide, Sit) upon entering.
func lock_pose(forced_pose: Type) -> void:
	_locked_pose = forced_pose
	_set_pose(forced_pose)


## Releases a previously locked pose, returning control to standard locomotion evaluation.
## Used by specialized states upon exiting.
func unlock_pose() -> void:
	_locked_pose = -1


## Returns the appropriate maximum speed for the currently active pose.
func get_current_speed_limit() -> float:
	match current_pose:
		Type.STANDING: return walk_speed
		Type.CROUCHING: return crouch_speed
		Type.PRONE: return prone_speed
		Type.SITTING: return 0.0
	return walk_speed


## Casts the headroom sensor upward to ensure clearance.
func _can_physically_stand() -> bool:
	if not headroom_sensor: 
		return true
		
	headroom_sensor.target_position = Vector3.ZERO 
	headroom_sensor.force_shapecast_update() 
	
	return not headroom_sensor.is_colliding()

## Internally updates the pose and broadcasts the change if it differs.
func _set_pose(new_pose: Type) -> void:
	if new_pose == current_pose:
		return
		
	var old_pose: Type = current_pose
	current_pose = new_pose
	pose_changed.emit(new_pose, old_pose)
