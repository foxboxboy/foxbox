# What you are holding. Nothing about looking lives here.
#
# Left click picks up and puts down, right drag turns what is held, the wheel raises and lowers
# it. Mouse buttons are read as raw events rather than named actions, so this works in a project
# that has not set up an input map.
extends Node3D




#region Variables

## Typed against the preloaded script rather than a class_name, so the demo does not put a name
## as ordinary as Player3D into every project that opens it.
const Player3D = preload("res://demos/interaction/3d/player_3d.gd")

## Degrees of turn per pixel of mouse movement while the right button is down.
const SPIN_PER_PIXEL: float = 0.2

## How far ahead of the object the commanded orientation may get. The torque takes the shortest
## way to its target, so past half a turn the shortest way is backwards and the object unwinds
## against the drag. A quarter turn leaves room to lag without ever crossing over.
const MAX_SPIN_LEAD: float = PI / 2.0

## Metres the wheel raises or lowers what is held, and the range it may sit in.
const LIFT_STEP: float = 0.5
const LIFT_RANGE: Vector2 = Vector2(0.0, 5.0)

@export var player: Player3D
@export var dragger: FoxPhysicsDragger3D

## Sits on the spot the object is pulled by, which is neither its centre nor the cursor.
@export var grab_marker: MeshInstance3D

var _held: RigidBody3D = null
var _turning: bool = false

## How far above the point under the cursor the object floats. Without it a carried object
## scrapes along whatever is beneath it.
var _lift: float = 0.5

## Where the cursor was when a turn started, so it can be put back.
var _cursor_before_turn: Vector2 = Vector2.ZERO

#endregion




#region Built-In Virtuals

## The dragger is a target the object is pulled towards, not a hand that carries it. It is placed
## in physics because that is where the pull is applied.
func _physics_process(_delta: float) -> void:
	if _turning:
		# Hold it exactly where it was. The cursor is not trustworthy while captured.
		return

	dragger.global_position = player.get_cursor_world_point() + Vector3.UP * _lift


func _process(_delta: float) -> void:
	_show_grab_point()

#endregion




#region Public API

## Whether something is in hand. Read by the readout.
func is_holding() -> bool:
	return is_instance_valid(_held)


## Whether a turn is in progress, and therefore whether the cursor is captured.
func is_turning() -> bool:
	return _turning


## How far above the ground the held object is floating.
func get_lift() -> float:
	return _lift


## Called back by an object that was interacted with. The object decides that being interacted
## with means being picked up; this is the half that can actually do it.
func grab_body(body: RigidBody3D, profile: FoxPhysicsDragProfile) -> void:
	_grab(body, profile)

#endregion




#region Input

func _unhandled_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button:
		_on_mouse_button(button)
		return

	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion and _turning and is_holding():
		_turn_held(motion.relative)


## Picking up is a toggle rather than a hold. Ending the cursor capture at the end of a turn
## makes the window manager report the left button as released, and while holding meant held that
## silently dropped whatever was being turned. A toggle cannot be undone by an event nobody sent.
func _on_mouse_button(button: InputEventMouseButton) -> void:
	if not button.pressed:
		if button.button_index == MOUSE_BUTTON_RIGHT:
			_stop_turning()
		return

	match button.button_index:
		MOUSE_BUTTON_LEFT:
			if is_holding():
				_release()
			else:
				_try_grab()
		MOUSE_BUTTON_RIGHT:
			_start_turning()
		MOUSE_BUTTON_WHEEL_UP:
			_lift = clampf(_lift + LIFT_STEP, LIFT_RANGE.x, LIFT_RANGE.y)
		MOUSE_BUTTON_WHEEL_DOWN:
			_lift = clampf(_lift - LIFT_STEP, LIFT_RANGE.x, LIFT_RANGE.y)

#endregion




#region Carrying

## The grab point is a fixed spot on the object, so it travels as the object moves and turns.
func _show_grab_point() -> void:
	grab_marker.visible = dragger.is_holding()
	if grab_marker.visible:
		grab_marker.global_position = dragger.get_grab_point()


func _try_grab() -> void:
	var target: FoxInteractableArea3D = player.get_target()
	if target:
		target.interact(self)


func _grab(body: RigidBody3D, profile: FoxPhysicsDragProfile) -> void:
	if not is_instance_valid(body):
		return

	_held = body

	# Start level with the point under the cursor, so picking something up does not jerk it into
	# the air before you have asked it to rise.
	_lift = 0.0
	dragger.grab(body, player.get_hit_point(body.global_position), profile)


func _release() -> void:
	if not is_holding():
		return

	# Dropping mid turn would otherwise leave the cursor hidden with nothing to turn.
	_stop_turning()

	dragger.release(true)
	_held = null

#endregion




#region Turning

## Hides and locks the cursor for the duration of a turn. Refused with nothing in hand, since
## hiding the cursor for no reason is worse than not turning.
func _start_turning() -> void:
	if _turning or not is_holding():
		return

	_turning = true
	_cursor_before_turn = get_viewport().get_mouse_position()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	player.aiming_frozen = true


## Gives the cursor back exactly where it was taken from.
func _stop_turning() -> void:
	if not _turning:
		return

	_turning = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_viewport().warp_mouse(_cursor_before_turn)
	player.aiming_frozen = false


## Turning the dragger turns what it holds, because the torque targets the dragger's orientation.
## Yaw comes from horizontal movement and tumble from vertical, both about the camera's axes so
## the object turns the way the mouse moves rather than the way it happens to be facing.
func _turn_held(mouse_delta: Vector2) -> void:
	dragger.rotate(Vector3.UP, deg_to_rad(-mouse_delta.x * SPIN_PER_PIXEL))
	dragger.rotate(player.global_transform.basis.x, deg_to_rad(-mouse_delta.y * SPIN_PER_PIXEL))
	_rein_in_turn()


## Never let the command run further ahead than the object can follow. See MAX_SPIN_LEAD.
func _rein_in_turn() -> void:
	var held: Basis = _held.global_transform.basis.orthonormalized()
	var lead: Quaternion = (dragger.global_transform.basis.orthonormalized() * held.inverse()).get_rotation_quaternion()

	var angle: float = lead.get_angle()
	if angle > PI:
		angle -= TAU

	if absf(angle) <= MAX_SPIN_LEAD:
		return

	var reined: Transform3D = dragger.global_transform
	reined.basis = held * Basis(lead.get_axis().normalized(), clampf(angle, -MAX_SPIN_LEAD, MAX_SPIN_LEAD))
	dragger.global_transform = reined

#endregion
