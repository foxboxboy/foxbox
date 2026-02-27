@icon("uid://yv082b80h5oj")
extends FoxResource
class_name FoxBoundedValue
## A resource that manages a [float] value within a defined minimum and maximum range.
##
## Emits signals for overflow and underflow, allowing for secondary mechanics such as overkill or overhealing.


#region Signals

## Emitted when [member value], [member min_value], or [member max_value] changes.
signal value_changed(current: float, min: float, max: float)

## Emitted when [member value] falls below [member min_value]. 
## [param underflow] contains the absolute difference.
signal depleted(underflow: float)

## Emitted when [member value] exceeds [member max_value]. 
## [param overflow] contains the absolute difference.
signal saturated(overflow: float)

#endregion





#region Variables

## The maximum allowed value. Modifying this automatically clamps [member value].
@export var max_value : float = 1.0:
	set(v):
		max_value = v
		if min_value > max_value:
			push_warning("FoxBoundedValue: min_value (%s) is greater than max_value (%s)." % [min_value, max_value])
		_check_bounds()


## The minimum allowed value. Modifying this automatically clamps [member value].
@export var min_value : float = 0.0:
	set(v):
		min_value = v
		if min_value > max_value:
			push_warning("FoxBoundedValue: min_value (%s) is greater than max_value (%s)." % [min_value, max_value])
		_check_bounds()


## The current value. Automatically clamped between [member min_value] and [member max_value].
var value : float = 1.0:
	set(v):
		value = v
		_check_bounds()

#endregion





#region Public

## Decreases [member value] by [param amount].
func subtract(amount : float) -> void:
	self.value -= amount


## Increases [member value] by [param amount].
func add(amount : float) -> void:
	self.value += amount

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
