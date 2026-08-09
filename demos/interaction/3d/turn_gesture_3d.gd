# Right-drag to turn. Nothing here knows what is being turned, only how much and when.
#
# Everything below is about the mouse and the window, not about FoxFabric. It lives in its own file
# so hands_3d.gd can be about picking things up.
extends Node


#region Signals

## The gesture moved this far this frame, as radians about each screen axis.
signal turned(radians: Vector2)

## Emitted when the gesture starts and stops, so whatever is being turned can hold still and the
## player can stop aiming at a cursor that is not really there.
signal started
signal stopped

#endregion


#region Variables

## Degrees of turn per pixel of mouse movement.
const DEGREES_PER_PIXEL: float = 0.2

var _turning: bool = false

## Where the cursor was when the gesture started, so it can be put back.
var _cursor_before: Vector2 = Vector2.ZERO

## warp_mouse does not land until the window manager sends the next motion event. Until then the
## cursor still reads as the middle of the window, and anything following it jumps there.
var _awaiting_cursor: bool = false

#endregion


#region Public API

func is_turning() -> bool:
	return _turning


## Whether the cursor's position can be trusted yet. False for a frame or two after a gesture ends.
func is_cursor_settled() -> bool:
	return not _turning and not _awaiting_cursor


## Hides and locks the cursor. Refused when [param allowed] is false, since hiding the cursor with
## nothing to turn is worse than not turning.
func start(allowed: bool) -> void:
	if _turning or not allowed:
		return

	_turning = true
	_cursor_before = get_viewport().get_mouse_position()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	started.emit()


## Gives the cursor back exactly where it was taken from.
func stop() -> void:
	if not _turning:
		return

	_turning = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_viewport().warp_mouse(_cursor_before)
	_awaiting_cursor = true
	stopped.emit()

#endregion


#region Input

func _unhandled_input(event: InputEvent) -> void:
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion == null:
		return

	# The first movement after uncapturing is the one carrying a believable position.
	_awaiting_cursor = false

	if _turning:
		turned.emit(motion.relative * deg_to_rad(DEGREES_PER_PIXEL))

#endregion
