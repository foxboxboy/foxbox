@icon("uid://7wrva3q87qud")
class_name FoxZoomSpringArm3D
extends SpringArm3D
## An extended [SpringArm3D] designed for camera controllers.
##
## It overrides standard length adjustments with smooth, frame-independent 
## zoom interpolation and provides a dedicated API for stepping the zoom in and out.

## Emitted when the arm's zoom distance visually changes.
signal length_changed(new_length: float)

@export_group("Zoom Settings")

## The maximum distance the arm can zoom out.
@export var max_length: float = 200.0

## The amount of length added or subtracted per zoom input.
@export var zoom_step: float = 1.0

## How quickly the camera interpolates to the target zoom. Higher values mean faster zooming.
@export var zoom_speed: float = 10.0

## Determines if the node currently accepts zoom inputs.
@export var zoom_enabled: bool = true

## The desired length the arm is currently interpolating towards.
var target_length: float


#region Public API

## Decreases the target length by the [member zoom_step], bringing the camera closer.
func zoom_in() -> void:
	if zoom_enabled:
		change_zoom(-zoom_step)


## Increases the target length by the [member zoom_step], pushing the camera further away.
func zoom_out() -> void:
	if zoom_enabled:
		change_zoom(zoom_step)


## Directly modifies the target length by a specific [param amount], clamping it to [member max_length].
func change_zoom(amount: float) -> void:
	target_length = clampf(target_length + amount, 0.0, max_length)


## Returns the current visual zoom as a decimal between [code]0.0[/code] and [code]1.0[/code].
func get_zoom_percentage() -> float:
	if max_length == 0.0:
		return 0.0
		
	return spring_length / max_length

#endregion


#region Private Logic

func _ready() -> void:
	target_length = spring_length


func _process(delta: float) -> void:
	if not is_multiplayer_authority():
		return
		
	_update_zoom(delta)


func _update_zoom(delta: float) -> void:
	if is_equal_approx(spring_length, target_length):
		return
		
	var old_length := spring_length
	var new_length := lerpf(spring_length, target_length, 1.0 - exp(-zoom_speed * delta))
	
	if absf(new_length - target_length) < 0.01:
		new_length = target_length
		
	spring_length = new_length
	
	if spring_length != old_length:
		length_changed.emit(spring_length)

#endregion
