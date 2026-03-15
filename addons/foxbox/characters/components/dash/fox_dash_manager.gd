class_name FoxDashManager
extends FoxNode

## Component that manages the math, memory, and rules for a dash ability.
##
## Acts as a specialized stopwatch and data container, tracking cooldowns 
## and duration without directly applying physics.

## Emitted when a dash request is validated and consumed with [method consume].
signal consumed
## Emitted when a dash is requested with [method request].
signal requested
## Emitted when a pending dash is cancelled with [method cancel].
signal request_cancelled

@export_group("Physics")

## The burst speed applied to the character during the dash, in meters per second.
@export var speed: float = 20.0

## The total time the dash state remains active, in seconds.
@export var duration: float = 0.2

## The required wait time before another dash can be requested, in seconds.
@export var cooldown: float = 1.0


var _is_request_active: bool = false
var _last_dash_time: int = -100000


## Registers a request from the player or AI controller to perform a dash.
func request() -> void:
	if not _is_request_active:
		_is_request_active = true
		requested.emit()


## Cancels a pending dash request manually.
func cancel() -> void:
	if _is_request_active:
		_is_request_active = false
		request_cancelled.emit()


## Returns [code]true[/code] if a dash has been requested but not yet consumed.
func has_request() -> bool:
	return _is_request_active


## Returns [code]true[/code] if the dash cooldown timer has fully elapsed.
func is_available() -> bool:
	var time_since: float = (Time.get_ticks_msec() - _last_dash_time) / 1000.0
	return time_since >= cooldown


## Clears the current dash request, records the time, and alerts external systems.
func consume() -> void:
	_is_request_active = false
	_last_dash_time = Time.get_ticks_msec()
	consumed.emit()
