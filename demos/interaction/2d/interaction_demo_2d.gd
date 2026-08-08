# 2D counterpart to interaction_demo.tscn.
#
# Arrow keys move the player. The sensor turns to face the mouse, so what you can reach depends
# on where you stand as well as where you point. Click a prop to pick it up, release to drop it,
# and press Space to toggle keep_upright.
#
# Mouse buttons are read as raw events rather than named actions, so the scene works in a project
# that has not set up an input map.
extends Node2D

## How far the sensor reaches, in pixels.
const REACH: float = 190.0

## The reach line, drawn so it is obvious how far the sensor actually sees. Without it the range
## is invisible and pointing at a prop that is simply too far away looks like a broken demo.
const IDLE_COLOUR: Color = Color(1.0, 1.0, 1.0, 0.24)
const FOCUSED_COLOUR: Color = Color(1.0, 0.55, 0.1, 0.9)

@export var player: CharacterBody2D
@export var sensor: FoxInteractionRayCast2D
@export var dragger: FoxPhysicsDragger2D
@export var readout: Label
@export var reach_line: Line2D

## Pixels per second the player walks.
@export var move_speed: float = 320.0

## Degrees of spin per pixel of mouse movement while the right button is down.
const SPIN_PER_PIXEL: float = 0.4

var _held: RigidBody2D = null
var _keep_upright: bool = false
var _spinning: bool = false

## Where the cursor was when spinning started, so it can be put back.
var _cursor_before_spin: Vector2 = Vector2.ZERO

## Where the dragger was when spinning started. Held there for the whole spin.
var _dragger_before_spin: Vector2 = Vector2.ZERO

## Set on release, cleared by the first real mouse movement afterwards.
## [br][br]
## warp_mouse does not take effect until the window manager delivers the next motion event, so
## for a frame or two after uncapturing the reported cursor is still the middle of the window,
## which is where a captured cursor sits. Following it would fling whatever is held to the
## centre of the screen at the exact moment you let go.
var _awaiting_cursor: bool = false


func _ready() -> void:
	sensor.interaction_range = REACH
	sensor.focused.connect(_on_focus_changed)
	sensor.unfocused.connect(_on_focus_changed)
	_on_focus_changed(null)


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	player.velocity = direction * move_speed
	player.move_and_slide()


func _process(_delta: float) -> void:
	# A captured cursor reports the middle of the window, and for a frame or two after releasing
	# it still does. Either way the dragger holds exactly where it was, so nothing lurches.
	if _spinning or _awaiting_cursor:
		dragger.global_position = _dragger_before_spin
		_refresh_readout()
		return

	# Following the cursor happens on the render tick, not the physics one. Doing it in physics
	# stepped the arm at sixty hertz while the rest of the frame drew faster, which reads as
	# jitter even though nothing is actually wrong.
	var cursor := get_global_mouse_position()

	# The sensor is the player's reach, so it turns to face the cursor. FoxInteractionRayCast2D
	# casts along +X, which is what look_at points at, so aiming it is a single call.
	sensor.look_at(cursor)

	# The dragger is a target the held body is pulled towards, not a hand that carries it. Put it
	# under the cursor and the physics does the rest.
	dragger.global_position = cursor

	# Keep the dragger's angle on whatever the prop has drifted to, so the orientation spring has
	# nothing to pull against and a swing is allowed to stand. Without this the dragger's angle
	# stays level and every swing is straightened out again the moment the cursor stops.
	# [br]
	# Skipped while right dragging, where the angle is being chosen deliberately and copying the
	# prop back over it would undo the turn as fast as it was made.
	if is_instance_valid(_held) and not _spinning:
		dragger.global_rotation = _held.global_rotation


func _unhandled_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button and button.button_index == MOUSE_BUTTON_LEFT:
		if button.pressed:
			_try_grab()
		else:
			_release()
		return

	if button and button.button_index == MOUSE_BUTTON_RIGHT:
		if button.pressed:
			_start_spinning()
		else:
			_stop_spinning()
		return

	var motion := event as InputEventMouseMotion

	# The first movement after uncapturing is the one carrying a believable position, so this is
	# the moment it becomes safe to follow the cursor again.
	if motion and _awaiting_cursor:
		_awaiting_cursor = false

	# Turning the dragger turns what it is holding, because the torque targets the dragger's
	# rotation. With keep_upright on that target is level instead, so spinning does nothing.
	if motion and _spinning and is_instance_valid(_held):
		dragger.rotate(deg_to_rad(motion.relative.x * SPIN_PER_PIXEL))
		return

	var key := event as InputEventKey
	if key and key.pressed and not key.echo and key.keycode == KEY_SPACE:
		_keep_upright = not _keep_upright
		# Re-grab so the change takes effect on whatever is already in hand.
		if is_instance_valid(_held):
			var body := _held
			_release()
			_grab(body, null)
		_refresh_readout()


## Called back by a prop that was interacted with. The prop decides that being interacted with
## means being picked up; this is the half that can actually do it.
func grab_body(body: RigidBody2D, profile: FoxPhysicsDragProfile) -> void:
	_grab(body, profile)


## Hides and locks the cursor for the duration of a spin, and pins the dragger where it stands.
## [br][br]
## Refused with nothing in hand, since hiding the cursor for no reason is worse than not
## spinning at all.
func _start_spinning() -> void:
	if _spinning or not is_instance_valid(_held):
		return

	_spinning = true
	_cursor_before_spin = get_viewport().get_mouse_position()
	_dragger_before_spin = dragger.global_position
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_refresh_readout()


## Gives the cursor back exactly where it was taken from.
func _stop_spinning() -> void:
	if not _spinning:
		return

	_spinning = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_viewport().warp_mouse(_cursor_before_spin)

	# The warp is not visible to us until the next motion event, so keep holding until then.
	_awaiting_cursor = true
	_refresh_readout()


func _try_grab() -> void:
	var target := sensor.get_current_target()
	if target:
		target.interact(self)


func _grab(body: RigidBody2D, profile: FoxPhysicsDragProfile) -> void:
	if not is_instance_valid(body):
		return

	_held = body
	dragger.default_keep_upright = _keep_upright

	# Grab at the point on the body nearest the cursor rather than its centre, so a long prop
	# swings from where you took hold of it.
	dragger.grab(body, get_global_mouse_position(), profile)
	_refresh_readout()


func _release() -> void:
	if not is_instance_valid(_held):
		return

	# Dropping mid spin would otherwise leave the cursor hidden with nothing to turn.
	_stop_spinning()

	dragger.release()
	_held = null
	_refresh_readout()


func _on_focus_changed(_interactable: FoxInteractableArea2D) -> void:
	var has_target := sensor.get_current_target() != null
	reach_line.default_color = FOCUSED_COLOUR if has_target else IDLE_COLOUR
	_refresh_readout()


func _refresh_readout() -> void:
	var target := sensor.get_current_target()
	var pointing := "nothing"
	if target:
		var prop := target.get_parent()
		pointing = str(prop.label) if prop and "label" in prop else prop.name

	var upright := "on" if _keep_upright else "off"
	if _keep_upright:
		# Worth saying, or right dragging looks broken rather than overruled.
		upright += "  (held level, so spinning has no effect)"

	# The mouse state is on screen on purpose. Capturing the cursor is the part of this demo most
	# likely to misbehave, and it is impossible to describe what went wrong without seeing it.
	var modes := {
		Input.MOUSE_MODE_VISIBLE: "visible",
		Input.MOUSE_MODE_HIDDEN: "hidden",
		Input.MOUSE_MODE_CAPTURED: "captured",
		Input.MOUSE_MODE_CONFINED: "confined",
		Input.MOUSE_MODE_CONFINED_HIDDEN: "confined hidden",
	}

	readout.text = "\n".join([
		"Arrows move, mouse aims, left click grabs",
		"Right drag spins what you are holding, Space toggles upright",
		"",
		"pointing at:  %s" % pointing,
		"holding:      %s" % ("yes" if is_instance_valid(_held) else "no"),
		"spinning:     %s" % ("yes" if _spinning else "no"),
		"keep upright: %s" % upright,
		"",
		"mouse mode:   %s" % modes.get(Input.mouse_mode, str(Input.mouse_mode)),
		"cursor:       %s%s" % [
			str(get_viewport().get_mouse_position().round()),
			"   (holding, waiting for the warp)" if _awaiting_cursor else ""],
		"dragger:      %s" % str(dragger.global_position.round()),
	])
