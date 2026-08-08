# Where you are and where you are pointing. Nothing about carrying lives here.
#
# The sensor is a child of the player rather than of the cursor, so what you can reach depends on
# where you stand as well as where you point.
extends CharacterBody2D




#region Variables

## The reach line lights up when something is in range, so the range is not invisible.
const IDLE_COLOUR: Color = Color(1.0, 1.0, 1.0, 0.24)
const FOCUSED_COLOUR: Color = Color(1.0, 0.55, 0.1, 0.9)

@export var sensor: FoxInteractionRayCast2D

## Drawn along the sensor so you can see how far it actually sees.
@export var reach_line: Line2D

## Pixels per second the player walks.
@export var move_speed: float = 320.0

## Set while the cursor is captured for a turn. A captured cursor reports the middle of the
## window, so aiming at it would swing the arm to the centre of the screen and shake it there.
var aiming_frozen: bool = false

#endregion




#region Built-In Virtuals

func _ready() -> void:
	sensor.focused.connect(_on_focus_changed)
	sensor.unfocused.connect(_on_focus_changed)
	_on_focus_changed(null)


func _physics_process(_delta: float) -> void:
	var direction: Vector2 = Input.get_vector(&"ui_left", &"ui_right", &"ui_up", &"ui_down")
	velocity = direction * move_speed
	move_and_slide()


## Aiming follows the cursor, so it belongs on the render tick. Done in physics it steps at sixty
## hertz while the rest of the frame draws faster, which reads as jitter.
func _process(_delta: float) -> void:
	if aiming_frozen:
		return

	# FoxInteractionRayCast2D casts along +X, which is where look_at points, so aiming is one
	# call. Pointing off screen is fine, so this is not clamped.
	sensor.look_at(get_global_mouse_position())

#endregion




#region Public API

## What the sensor is pointing at, or [code]null[/code].
func get_target() -> FoxInteractableArea2D:
	return sensor.get_current_target()


## Where the sensor's ray struck, falling back to [param fallback] when it hit nothing.
## [br][br]
## This is the point to take hold of. The cursor is not: the sensor only points towards it, so
## the cursor is normally well past the prop, and grabbing there gives a lever longer than the
## prop itself.
func get_hit_point(fallback: Vector2) -> Vector2:
	return sensor.get_collision_point() if sensor.is_colliding() else fallback

#endregion




#region Private

func _on_focus_changed(_interactable: FoxInteractableArea2D) -> void:
	reach_line.default_color = FOCUSED_COLOUR if get_target() else IDLE_COLOUR

#endregion
