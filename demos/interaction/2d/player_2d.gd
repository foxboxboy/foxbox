# Walks with the arrow keys and points the interaction sensor at the cursor.
extends CharacterBody2D




#region Variables

const IDLE_COLOUR: Color = Color(1.0, 1.0, 1.0, 0.24)
const FOCUSED_COLOUR: Color = Color(1.0, 0.55, 0.1, 0.9)

@export var sensor: FoxInteractionRayCast2D

## Drawn along the sensor, and lit up while something is in range.
@export var reach_line: Line2D

## Pixels per second.
@export var move_speed: float = 320.0

## Set while the cursor is captured for a turn, when it reports the middle of the window.
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


# Aiming is on the render tick because in physics it steps at 60 Hz while the frame draws faster,
# which reads as jitter.
func _process(_delta: float) -> void:
	if aiming_frozen:
		return

	# FoxInteractionRayCast2D casts along +X, which is where look_at points.
	sensor.look_at(get_global_mouse_position())

#endregion




#region Public API

## What the sensor is pointing at, or [code]null[/code].
func get_target() -> FoxInteractableArea2D:
	return sensor.get_current_target()


## Where the ray struck, falling back to [param fallback] when it hit nothing.
## [br][br]
## Take hold here, not at the cursor. The cursor is usually well past the prop, which gives a
## lever longer than the prop itself.
func get_hit_point(fallback: Vector2) -> Vector2:
	return sensor.get_collision_point() if sensor.is_colliding() else fallback

#endregion




#region Private

func _on_focus_changed(_interactable: FoxInteractableArea2D) -> void:
	reach_line.default_color = FOCUSED_COLOUR if get_target() else IDLE_COLOUR

#endregion
