# 2D counterpart to interaction_demo.tscn.
#
# Arrow keys move the player. The sensor turns to face the mouse, so what you can reach depends
# on where you stand as well as where you point. Click a highlighted prop to pick it up, release
# to drop it, and press Space while holding to toggle keep_upright.
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


func _ready() -> void:
	sensor.interaction_range = REACH
	sensor.focused.connect(_on_focus_changed)
	sensor.unfocused.connect(_on_focus_changed)
	_on_focus_changed(null)


func _physics_process(_delta: float) -> void:
	var direction := Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	player.velocity = direction * move_speed
	player.move_and_slide()

	# The sensor is the player's reach, so it turns to face the cursor. FoxInteractionRayCast2D
	# casts along +X, which is what look_at points at, so aiming it is a single call.
	sensor.look_at(get_global_mouse_position())

	# The dragger is a target the held body is pulled towards, not a hand that carries it. Put it
	# under the cursor and the physics does the rest. While spinning it stays put, so the mouse
	# is free to mean rotation instead of position.
	if not _spinning:
		dragger.global_position = get_global_mouse_position()


func _unhandled_input(event: InputEvent) -> void:
	var button := event as InputEventMouseButton
	if button and button.button_index == MOUSE_BUTTON_LEFT:
		if button.pressed:
			_try_grab()
		else:
			_release()
		return

	if button and button.button_index == MOUSE_BUTTON_RIGHT:
		_spinning = button.pressed
		_refresh_readout()
		return

	# Turning the dragger turns what it is holding, because the torque targets the dragger's
	# rotation. With keep_upright on that target is level instead, so spinning does nothing.
	var motion := event as InputEventMouseMotion
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

	readout.text = "\n".join([
		"Arrows move, mouse aims, left click grabs",
		"Right drag spins what you are holding, Space toggles upright",
		"",
		"pointing at:  %s" % pointing,
		"holding:      %s" % ("yes" if is_instance_valid(_held) else "no"),
		"spinning:     %s" % ("yes" if _spinning else "no"),
		"keep upright: %s" % upright,
	])
