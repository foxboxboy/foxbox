# Left click picks up and puts down, right drag turns what is held, Space toggles keep_upright.
extends Node2D




#region Variables

const Player2D = preload("res://demos/interaction/2d/player_2d.gd")

## Where the dragger may go, matching the inside of the walls. The cursor can leave the window and
## Godot keeps reporting where it went, which would drag a prop out through a wall.
const ARENA: Rect2 = Rect2(-396.0, -236.0, 792.0, 472.0)

## Degrees of turn per pixel of mouse movement.
const SPIN_PER_PIXEL: float = 0.4

## How far ahead of the prop the commanded angle may get. The torque takes the shortest way to its
## target, so past half a turn the shortest way is backwards and the prop unwinds against the drag.
const MAX_SPIN_LEAD: float = PI / 2.0

@export var player: Player2D
@export var dragger: FoxPhysicsDragger2D

## Marks the spot the prop is pulled by, which is neither its centre nor the cursor.
@export var grab_marker: Polygon2D

var _held: RigidBody2D = null
var _keep_upright: bool = false
var _turning: bool = false

## Where the cursor and dragger were when a turn started, so both can be put back.
var _cursor_before_turn: Vector2 = Vector2.ZERO
var _dragger_before_turn: Vector2 = Vector2.ZERO

## warp_mouse does not land until the window manager sends the next motion event. Until then the
## cursor still reads as the middle of the window, and following it would fling the prop there.
var _awaiting_cursor: bool = false

#endregion




#region Built-In Virtuals

func _process(_delta: float) -> void:
	_show_grab_point()

	if _turning or _awaiting_cursor:
		dragger.global_position = _dragger_before_turn
		return

	_carry_towards_cursor()

#endregion




#region Public API

func is_holding() -> bool:
	return is_instance_valid(_held)


func is_upright() -> bool:
	return _keep_upright


## Called by a prop that was interacted with.
func grab_body(body: RigidBody2D, profile: FoxPhysicsDragProfile) -> void:
	_grab(body, profile)

#endregion




#region Input

func _unhandled_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button:
		_on_mouse_button(button)
		return

	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion:
		_on_mouse_motion(motion)
		return

	var key: InputEventKey = event as InputEventKey
	if key and key.pressed and not key.echo and key.keycode == KEY_SPACE:
		_toggle_upright()


# Picking up toggles instead of holding, because ending the cursor capture at the end of a turn
# makes the window manager report the left button as released, which silently dropped whatever was
# being turned.
func _on_mouse_button(button: InputEventMouseButton) -> void:
	if button.button_index == MOUSE_BUTTON_LEFT and button.pressed:
		if is_holding():
			_release()
		else:
			_try_grab()

	elif button.button_index == MOUSE_BUTTON_RIGHT:
		if button.pressed:
			_start_turning()
		else:
			_stop_turning()


func _on_mouse_motion(motion: InputEventMouseMotion) -> void:
	# The first movement after uncapturing is the one carrying a believable position.
	_awaiting_cursor = false

	if _turning and is_holding():
		_turn_held(motion.relative.x)


func _toggle_upright() -> void:
	_keep_upright = not _keep_upright

	# Re-grab so the change reaches whatever is already in hand.
	if is_holding():
		var body: RigidBody2D = _held
		_release()
		_grab(body, null)

#endregion




#region Carrying

# The dragger is a target the prop is pulled towards, so moving it does not move the prop directly.
func _carry_towards_cursor() -> void:
	dragger.global_position = get_global_mouse_position().clamp(ARENA.position, ARENA.end)

	# Keep the commanded angle on whatever the prop has drifted to, so the orientation spring has
	# nothing to pull against and a swing is allowed to stand. Turning sets the angle deliberately,
	# so that path skips this.
	if is_holding():
		dragger.global_rotation = _held.global_rotation


func _show_grab_point() -> void:
	grab_marker.visible = dragger.is_holding()
	if grab_marker.visible:
		grab_marker.global_position = dragger.get_grab_point()


func _try_grab() -> void:
	var target: FoxInteractableArea2D = player.get_target()
	if target:
		target.interact(self)


func _grab(body: RigidBody2D, profile: FoxPhysicsDragProfile) -> void:
	if not is_instance_valid(body):
		return

	_held = body
	dragger.default_keep_upright = _keep_upright
	dragger.grab(body, player.get_hit_point(body.global_position), profile)


func _release() -> void:
	if not is_holding():
		return

	# Dropping mid turn would leave the cursor hidden with nothing to turn.
	_stop_turning()

	dragger.release()
	_held = null

#endregion




#region Turning

## Hides and locks the cursor, and pins the dragger where it stands.
func _start_turning() -> void:
	if _turning or not is_holding():
		return

	_turning = true
	_cursor_before_turn = get_viewport().get_mouse_position()
	_dragger_before_turn = dragger.global_position
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	player.aiming_frozen = true


## Gives the cursor back exactly where it was taken from.
func _stop_turning() -> void:
	if not _turning:
		return

	_turning = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_viewport().warp_mouse(_cursor_before_turn)
	_awaiting_cursor = true
	player.aiming_frozen = false


## Turning the dragger turns what it holds, because the torque targets the dragger's angle. With
## keep_upright on that target is level, so turning does nothing.
func _turn_held(mouse_dx: float) -> void:
	dragger.rotate(deg_to_rad(mouse_dx * SPIN_PER_PIXEL))

	# See MAX_SPIN_LEAD.
	var lead: float = angle_difference(_held.global_rotation, dragger.global_rotation)
	dragger.global_rotation = _held.global_rotation + clampf(lead, -MAX_SPIN_LEAD, MAX_SPIN_LEAD)

#endregion
