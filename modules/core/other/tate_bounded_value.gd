extends TateResource
class_name TateBoundedValue
## A generic resource that manages a float value within a defined range.
## Tracks "overflow" and "underflow" to allow for secondary mechanics like overkill.

#region Signals

## Emitted whenever the current value changes.
signal value_changed(current: float, max: float, min: float)

## Emitted when the value falls below the minimum limit.
## underflow: the negative amount 'left over' (e.g., -5.0 if 30 was taken from 25).
signal depleted(underflow: float)

## Emitted when the value hits or exceeds the maximum limit.
## overflow: the amount exceeding the limit (e.g., 20.0 if 30 was added to 90/100).
signal saturated(overflow: float)

#endregion

#region Variables

## The upper bound of the value.
@export var max_limit : float = 1.0:
	set(v):
		max_limit = v
		_check_bounds()

## The lower bound of the value.
@export var min_limit : float = 0.0:
	set(v):
		min_limit = v
		_check_bounds()

## The actual fluctuating state.
var current_value : float = 1.0:
	set(v):
		current_value = v # We allow temporary out-of-bounds for calculation
		_check_bounds()

#endregion

#region API

func _init(p_max: float = 1.0, p_min: float = 0.0):
	max_limit = p_max
	min_limit = p_min
	current_value = max_limit

## Standard way to decrease the value.
func subtract(amount : float) -> void:
	current_value -= amount

## Standard way to increase the value.
func add(amount : float) -> void:
	current_value += amount

#endregion

#region Private

func _check_bounds() -> void:
	# Calculate overflow/underflow before clamping
	if current_value < min_limit:
		var underflow = current_value - min_limit
		current_value = min_limit
		depleted.emit(underflow)
	
	elif current_value > max_limit:
		var overflow = current_value - max_limit
		current_value = max_limit
		saturated.emit(overflow)
	
	value_changed.emit(current_value, max_limit, min_limit)

#endregion
