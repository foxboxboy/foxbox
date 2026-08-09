# Left click picks up and puts down, right drag turns what is held, the wheel raises and lowers it.
extends Node3D




#region Variables

const Player3D = preload("res://demos/interaction/3d/player_3d.gd")
const TurnGesture3D = preload("res://demos/interaction/3d/turn_gesture_3d.gd")

## Metres the wheel raises or lowers what is held, and the range it may sit in.
const LIFT_STEP: float = 0.5
const LIFT_RANGE: Vector2 = Vector2(0.0, 5.0)

@export var player: Player3D
@export var dragger: FoxPhysicsDragger3D

## Runs the right-drag itself. All this has to do is say what the turning is for.
@export var turn: TurnGesture3D

## Marks the spot the object is pulled by, which is neither its centre nor the cursor.
@export var grab_marker: MeshInstance3D

var _held: RigidBody3D = null

## How far above the point under the cursor the object floats. At zero a carried object scrapes
## along whatever is beneath it.
var _lift: float = 0.5

#endregion




#region Built-In Virtuals

func _ready() -> void:
	turn.started.connect(_on_turn_started)
	turn.stopped.connect(_on_turn_stopped)
	turn.turned.connect(_on_turned)


# In physics because that is where the pull is applied.
func _physics_process(_delta: float) -> void:
	if not turn.is_cursor_settled():
		return

	dragger.global_position = player.get_cursor_world_point() + Vector3.UP * _lift


func _process(_delta: float) -> void:
	_show_grab_point()

#endregion




#region Public API

func is_holding() -> bool:
	return is_instance_valid(_held)


func get_lift() -> float:
	return _lift


## Called by an object that was interacted with.
func grab_body(body: RigidBody3D, profile: FoxPhysicsDragProfile) -> void:
	_grab(body, profile)

#endregion




#region Input

func _unhandled_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button:
		_on_mouse_button(button)


# Picking up toggles instead of holding, because ending the cursor capture at the end of a turn
# makes the window manager report the left button as released, which silently dropped whatever was
# being turned.
func _on_mouse_button(button: InputEventMouseButton) -> void:
	if not button.pressed:
		if button.button_index == MOUSE_BUTTON_RIGHT:
			turn.stop()
		return

	match button.button_index:
		MOUSE_BUTTON_LEFT:
			if is_holding():
				_release()
			else:
				_try_grab()
		MOUSE_BUTTON_RIGHT:
			turn.start(is_holding())
		MOUSE_BUTTON_WHEEL_UP:
			_lift = clampf(_lift + LIFT_STEP, LIFT_RANGE.x, LIFT_RANGE.y)
		MOUSE_BUTTON_WHEEL_DOWN:
			_lift = clampf(_lift - LIFT_STEP, LIFT_RANGE.x, LIFT_RANGE.y)

#endregion




#region Carrying

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

	# Dropping mid turn would leave the cursor hidden with nothing to turn.
	turn.stop()

	dragger.release()
	_held = null

#endregion




#region Turning

func _on_turn_started() -> void:
	player.aiming_frozen = true


func _on_turn_stopped() -> void:
	player.aiming_frozen = false


## Turning the dragger turns what it holds, because the torque targets the dragger's orientation.
## Yaw comes from horizontal movement and tumble from vertical, both about the camera's axes, so
## the object turns the way the mouse moves. The dragger refuses to be turned further ahead than
## the object can follow, so nothing here has to watch for that.
func _on_turned(radians: Vector2) -> void:
	if not is_holding():
		return

	dragger.rotate(Vector3.UP, -radians.x)
	dragger.rotate(player.global_transform.basis.x, -radians.y)

#endregion
