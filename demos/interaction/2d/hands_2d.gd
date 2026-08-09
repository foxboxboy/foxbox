# Left click picks up and puts down, right drag turns what is held, Space toggles keep_upright.
extends Node2D




#region Variables

const Player2D = preload("res://demos/interaction/2d/player_2d.gd")
const TurnGesture2D = preload("res://demos/interaction/2d/turn_gesture_2d.gd")

## Where the dragger may go, matching the inside of the walls. The cursor can leave the window and
## Godot keeps reporting where it went, which would drag a prop out through a wall.
const ARENA: Rect2 = Rect2(-396.0, -236.0, 792.0, 472.0)

@export var player: Player2D
@export var dragger: FoxPhysicsDragger2D

## Runs the right-drag itself. All this has to do is say what the turning is for.
@export var turn: TurnGesture2D

## Marks the spot the prop is pulled by, which is neither its centre nor the cursor.
@export var grab_marker: Polygon2D

var _held: RigidBody2D = null
var _keep_upright: bool = false

## Where the dragger was when a turn started, so it can be held there.
var _dragger_before_turn: Vector2 = Vector2.ZERO

#endregion




#region Built-In Virtuals

func _ready() -> void:
	turn.started.connect(_on_turn_started)
	turn.stopped.connect(_on_turn_stopped)
	turn.turned.connect(_on_turned)


## Carrying follows the cursor, so it belongs on the render tick alongside aiming.
func _process(_delta: float) -> void:
	_show_grab_point()

	if not turn.is_cursor_settled():
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
			turn.start(is_holding())
		else:
			turn.stop()


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
	turn.stop()

	dragger.release()
	_held = null

#endregion




#region Turning

func _on_turn_started() -> void:
	_dragger_before_turn = dragger.global_position
	player.aiming_frozen = true


func _on_turn_stopped() -> void:
	player.aiming_frozen = false


## Turning the dragger turns what it holds, because the torque targets the dragger's angle. The
## dragger refuses to be turned further ahead than the prop can follow, so nothing here has to
## watch for that. With keep_upright on the target is level instead, so turning does nothing.
func _on_turned(radians: float) -> void:
	if is_holding():
		dragger.rotate(radians)

#endregion
