@tool
@icon("uid://7wrva3q87qud")
class_name FoxZoomSpringArm3D
extends SpringArm3D
## An extended [SpringArm3D] designed for camera controllers.
##
## [FoxZoomSpringArm3D] overrides standard length adjustments with smooth, frame-independent
## zoom interpolation and provides a dedicated API for stepping the zoom in and out.

## Emitted when the arm's zoom distance visually changes.
signal length_changed(new_length: float)

## Emitted the moment the arm's length reaches 0.0. Useful for hiding the player mesh.
signal zoom_min_reached

## Emitted the moment the arm reaches its [member max_length].
signal zoom_max_reached

## Emitted when the arm finishes interpolating and completely settles on the [member target_length].
signal zoom_finished

@export_group("Zoom Settings")

## The maximum distance the arm can zoom out.
@export var max_length: float = 200.0:
	set(value):
		max_length = value
		update_configuration_warnings()

## The amount of length added or subtracted per zoom input.
@export var zoom_step: float = 1.0

## How quickly the camera interpolates to the target zoom. Higher values mean faster zooming.
@export var zoom_speed: float = 10.0:
	set(value):
		zoom_speed = value
		update_configuration_warnings()

## If [code]true[/code], the node accepts zoom inputs.
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




#region Private

func _ready() -> void:
	# @tool runs this in the editor too, where it would touch live state.
	if Engine.is_editor_hint():
		return

	target_length = spring_length


func _process(delta: float) -> void:
	# @tool runs this in the editor too, where it would touch live state.
	if Engine.is_editor_hint():
		return

	if not is_multiplayer_authority():
		return

	_update_zoom(delta)


func _update_zoom(delta: float) -> void:
	var should_zoom := not is_equal_approx(spring_length, target_length)
	if not should_zoom:
		return

	var old_length := spring_length

	spring_length = _calculate_smooth_length(delta)

	_emit_zoom_signals(old_length)


func _calculate_smooth_length(delta: float) -> float:
	var new_length := lerpf(spring_length, target_length, 1.0 - exp(-zoom_speed * delta))

	if absf(new_length - target_length) < 0.01:
		return target_length

	return new_length


func _emit_zoom_signals(old_length: float) -> void:
	if spring_length != old_length:
		length_changed.emit(spring_length)

	# Check for limits and completion
	if is_equal_approx(spring_length, target_length):
		zoom_finished.emit()

		if is_equal_approx(spring_length, 0.0):
			zoom_min_reached.emit()
		elif is_equal_approx(spring_length, max_length):
			zoom_max_reached.emit()

#endregion




#region Editor

func _get_configuration_warnings() -> PackedStringArray:
	var warnings: PackedStringArray = []

	if max_length <= 0.0:
		warnings.append("Max Length is %s, so the arm can never extend." % max_length)

	if zoom_speed <= 0.0:
		warnings.append("Zoom Speed is %s, so the arm will never reach its target length."
			% zoom_speed)

	return warnings

#endregion
