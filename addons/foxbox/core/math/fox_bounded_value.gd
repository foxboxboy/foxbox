extends FoxResource
class_name FoxBoundedValue
## A generic resource that manages a float value within a defined range.
## Tracks "overflow" and "underflow" to allow for secondary mechanics like overkill.

#region Signals

## Emitted whenever the current value changes.
signal value_changed(current: float, min: float, max: float)

## Emitted when the value falls below the minimum limit.
## underflow: the negative amount 'left over' (e.g., -5.0 if 30 was taken from 25).
signal depleted(underflow: float)

## Emitted when the value hits or exceeds the maximum limit.
## overflow: the amount exceeding the limit (e.g., 20.0 if 30 was added to 90/100).
signal saturated(overflow: float)

#endregion

#region Variables

## The upper bound of the value.
@export var max_value : float = 1.0:
	set(v):
		max_value = v
		_check_bounds()

## The lower bound of the value.
@export var min_value : float = 0.0:
	set(v):
		min_value = v
		_check_bounds()

## The actual fluctuating value.
var value : float = 1.0:
	set(v):
		value = v
		_check_bounds()

#endregion

#region Public

## Decreases the value.
func subtract(amount : float) -> void:
	value -= amount

## Increases the value.
func add(amount : float) -> void:
	value += amount

#endregion

#region Private

func _init(starting_value := 1.0, p_max: float = 1.0, p_min: float = 0.0):
	max_value = p_max
	min_value = p_min
	value = starting_value

func _check_bounds() -> void:
	# overflow/underflow
	if value < min_value:
		var underflow = value - min_value
		value = min_value
		depleted.emit(underflow)
	
	elif value > max_value:
		var overflow = value - max_value
		value = max_value
		saturated.emit(overflow)
	
	value_changed.emit(value, max_value, min_value)

#endregion
