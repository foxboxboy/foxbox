@icon("uid://yv082b80h5oj")
extends FoxResource
class_name FoxBoundedValue
## A resource that manages a [float] value within a defined minimum and maximum range.
##
## [FoxBoundedValue] emits signals for overflow and underflow, allowing for secondary mechanics such as overkill or overhealing.




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

## Suppresses the inverted-bounds warning while _init assigns both bounds.
var _constructing: bool = false

## The maximum allowed value. Modifying this automatically clamps [member value].
@export var max_value : float = 1.0:
	set(v):
		max_value = v
		if min_value > max_value and not _constructing:
			push_warning("FoxBoundedValue: min_value (%s) is greater than max_value (%s)." % [min_value, max_value])
		_reclamp()


## The minimum allowed value. Modifying this automatically clamps [member value].
@export var min_value : float = 0.0:
	set(v):
		min_value = v
		if min_value > max_value and not _constructing:
			push_warning("FoxBoundedValue: min_value (%s) is greater than max_value (%s)." % [min_value, max_value])
		_reclamp()


## The current value. Automatically clamped between [member min_value] and [member max_value].
## [br][br]
## If the bounds are ever inverted, the narrower of the two is still respected rather than the
## value bouncing between them.
var value : float = 1.0:
	set(v):
		# Clamp on the way in. The previous version assigned first and corrected afterwards,
		# which re-entered this setter and looped forever whenever min was above max.
		var lo := minf(min_value, max_value)
		var hi := maxf(min_value, max_value)

		value = clampf(v, lo, hi)

		if v < lo:
			depleted.emit(lo - v)
		elif v > hi:
			saturated.emit(v - hi)

		value_changed.emit(value, min_value, max_value)

#endregion




#region Public API

## Decreases [member value] by [param amount].
func subtract(amount : float) -> void:
	self.value -= amount


## Increases [member value] by [param amount].
func add(amount : float) -> void:
	self.value += amount

#endregion




#region Private

## Builds a value of [param starting_value] bounded by [param p_min] and [param p_max].
## [br][br]
## Note the argument order: the value comes first, then the maximum, then the minimum.
## The value is clamped into range immediately.
func _init(starting_value: float = 1.0, p_max: float = 1.0, p_min: float = 0.0) -> void:
	# The bounds go in one at a time, so the pair is briefly inconsistent no matter which order
	# they are assigned. Hold the warning until both are in place, then check once.
	_constructing = true
	max_value = p_max
	min_value = p_min
	_constructing = false

	if min_value > max_value:
		push_warning("FoxBoundedValue: min_value (%s) is greater than max_value (%s)." % [min_value, max_value])

	value = starting_value


## See FoxModifiableStat._to_string. An object crossing the debugger arrives as an encoded id, so
## this is the only chance to say something useful about it.
func _to_string() -> String:
	return "%s (%s to %s)" % [value, min_value, max_value]


## Re-runs the clamp against the current bounds. Called when either bound moves.
func _reclamp() -> void:
	# Assigning the property to itself runs the setter exactly once, which clamps and reports.
	# It cannot recurse, because the setter no longer calls back into here.
	value = value

#endregion
