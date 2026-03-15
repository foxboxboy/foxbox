class_name FoxSprintManager
extends FoxNode

## Component that manages the intents and threshold math for sprinting.
##
## Tracks the player's sprint requests and provides the speed variables 
## needed by the state machine, decoupling locomotion tuning from the root character.

## Emitted when a sprint is requested.
signal requested
## Emitted when a sprint request is cancelled.
signal cancelled

@export_group("Physics")

## The target speed when sprinting, in meters per second.
@export var speed: float = 9.0

## The percentage of sprint_speed the character's velocity must drop below 
## to automatically break out of a sprint. (Default 0.05 = 5%).
@export var dropoff_threshold: float = 0.05


var _is_requested: bool = false


## Registers an intent from the controller to sprint.
func request() -> void:
	if not _is_requested:
		_is_requested = true
		requested.emit()


## Cancels a pending sprint intent.
func cancel() -> void:
	if _is_requested:
		_is_requested = false
		cancelled.emit()


## Returns true if a sprint is currently being requested.
func is_requested() -> bool:
	return _is_requested


## Evaluates a given velocity against the dropoff threshold.
## Used by the state machine to force-cancel a sprint if the character hits a wall.
func is_below_dropoff(current_velocity: float) -> bool:
	var minimum_required_speed: float = speed * dropoff_threshold
	return current_velocity < minimum_required_speed
