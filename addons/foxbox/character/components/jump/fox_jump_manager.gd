class_name FoxJumpManager
extends FoxNode

## Component that manages the math, memory, and rules for jumping.
##
## Tracks jump buffers, coyote time, and multi-jump charges without
## directly interacting with the character motor or physics body.

## Emitted when a jump request is validated and consumed with [method consume].
signal consumed
## Emitted when a jump is requested with [method request].
signal requested
## Emitted when a pending jump is cancelled with [method cancel].
signal request_cancelled

@export_group("Physics")

## Maximum number of jumps allowed before landing (1 = Normal, 2 = Double Jump).
@export var max_jumps: int = 1

## How long the player can still jump after walking off a ledge, in seconds.
@export var coyote_duration: float = 0.15

## How long a jump input is remembered before hitting the ground, in seconds.
@export var buffer_time: float = 0.1

## The multiplier used for the jump force when jumping from a crouched position.
@export var crouch_multiplier: float = 1.2


var _is_request_active: bool = false
var _jumps_made: int = 0
var _last_grounded_time: int = -100000
var _last_jump_time: int = -100000
var _buffer_timer: float = 0.0


func _process(delta: float) -> void:
	# The manager handles its own buffer countdown!
	if _is_request_active:
		_buffer_timer -= delta
		if _buffer_timer <= 0.0:
			cancel()


## Registers a request to jump and starts the buffer timer.
func request() -> void:
	if not _is_request_active:
		_is_request_active = true
		_buffer_timer = buffer_time
		requested.emit()


## Cancels a pending jump request manually or when the buffer expires.
func cancel() -> void:
	if _is_request_active:
		_is_request_active = false
		request_cancelled.emit()


## Returns [code]true[/code] if a jump is currently buffered.
func has_request() -> bool:
	return _is_request_active


## Returns true if a jump is legally allowed (grounded, coyote, or multi-jump).
func is_available(is_grounded: bool) -> bool:
	var elapsed: float = (Time.get_ticks_msec() - _last_jump_time) / 1000.0
	if elapsed <= 0.15:
		return false
		
	if is_grounded:
		return true
		
	# Mid-Air Logic
	var time_since_ground: float = (Time.get_ticks_msec() - _last_grounded_time) / 1000.0
	
	# Coyote Jump (First jump, just stepped off)
	var can_coyote: bool = (_jumps_made == 0) and (time_since_ground <= coyote_duration)
	
	# Multi-Jump 
	var jumps_spent = _jumps_made
	if jumps_spent == 0 and time_since_ground > coyote_duration:
		# If they fell off a ledge and missed coyote time, the 1st jump is forfeit.
		jumps_spent = 1 

	var can_multi: bool = jumps_spent < max_jumps
	
	return can_coyote or can_multi


## Clears the buffer, increments the jump counter, and records the timestamp.
func consume() -> void:
	_is_request_active = false
	
	var time_since_ground: float = (Time.get_ticks_msec() - _last_grounded_time) / 1000.0
	
	# If they used a double-jump after falling off a ledge, we must charge them for 2 jumps.
	if _jumps_made == 0 and time_since_ground > coyote_duration:
		_jumps_made = 2
	else:
		_jumps_made += 1
		
	_last_jump_time = Time.get_ticks_msec()
	consumed.emit()


## Resets the multi-jump counter to zero. Typically called when landing.
func reset_count() -> void:
	_jumps_made = 0


## Records the exact millisecond the character was last touching the ground.
func update_grounded_time() -> void:
	_last_grounded_time = Time.get_ticks_msec()
