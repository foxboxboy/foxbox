extends "res://tests/fox_test.gd"


func run() -> void:
	suite = "bounded_value"
	_construction()
	_arithmetic()
	_saturation()
	_depletion()
	_signal_argument_order()
	_moving_the_bounds()
	_random_sequences_stay_in_range()


func _construction() -> void:
	case("construction")
	var v := FoxBoundedValue.new(5.0, 10.0, 0.0)
	almost(v.value, 5.0, "starting value kept")
	almost(v.min_value, 0.0, "min kept")
	almost(v.max_value, 10.0, "max kept")

	var clamped := FoxBoundedValue.new(50.0, 10.0, 0.0)
	almost(clamped.value, 10.0, "starting value above max is clamped down")

	var floored := FoxBoundedValue.new(-50.0, 10.0, 0.0)
	almost(floored.value, 0.0, "starting value below min is clamped up")


func _arithmetic() -> void:
	case("add and subtract")
	var v := FoxBoundedValue.new(5.0, 10.0, 0.0)
	v.subtract(2.0)
	almost(v.value, 3.0, "subtract lowers the value")
	v.add(4.0)
	almost(v.value, 7.0, "add raises the value")
	v.add(0.0)
	almost(v.value, 7.0, "adding zero is a no-op")


func _saturation() -> void:
	case("saturation")
	var v := FoxBoundedValue.new(8.0, 10.0, 0.0)
	var overflow := [-1.0]
	v.saturated.connect(func(o: float) -> void: overflow[0] = o)

	v.add(5.0)
	almost(v.value, 10.0, "value stops at max")
	almost(overflow[0], 3.0, "overflow reports the excess above max")


func _depletion() -> void:
	case("depletion")
	var v := FoxBoundedValue.new(2.0, 10.0, 0.0)
	var underflow := [-1.0]
	v.depleted.connect(func(u: float) -> void: underflow[0] = u)

	v.subtract(6.0)
	almost(v.value, 0.0, "value stops at min")
	almost(underflow[0], 4.0, "underflow reports the shortfall below min")


## Regression: value_changed used to emit (value, max, min) into a signal declared
## as (current, min, max), so every listener read the bounds backwards.
func _signal_argument_order() -> void:
	case("value_changed argument order")
	var v := FoxBoundedValue.new(5.0, 100.0, 10.0)
	var got := [0.0, 0.0, 0.0]
	v.value_changed.connect(func(c: float, mn: float, mx: float) -> void:
		got[0] = c
		got[1] = mn
		got[2] = mx)

	v.add(20.0)
	almost(got[0], 30.0, "first argument is the current value")
	almost(got[1], 10.0, "second argument is the minimum, not the maximum")
	almost(got[2], 100.0, "third argument is the maximum, not the minimum")


func _moving_the_bounds() -> void:
	case("moving the bounds re-clamps")
	var v := FoxBoundedValue.new(9.0, 10.0, 0.0)
	v.max_value = 5.0
	almost(v.value, 5.0, "lowering max pulls the value down with it")

	var w := FoxBoundedValue.new(1.0, 10.0, 0.0)
	w.min_value = 4.0
	almost(w.value, 4.0, "raising min pushes the value up with it")


func _random_sequences_stay_in_range() -> void:
	case("invariant under random operations")
	var breaches := 0
	for i in 300:
		var lo := rng.randf_range(-50.0, 0.0)
		var hi := lo + rng.randf_range(0.1, 100.0)
		var v := FoxBoundedValue.new(rng.randf_range(lo, hi), hi, lo)

		for j in 20:
			if rng.randf() < 0.5:
				v.add(rng.randf_range(0.0, 30.0))
			else:
				v.subtract(rng.randf_range(0.0, 30.0))

			if v.value < lo - 0.0001 or v.value > hi + 0.0001:
				breaches += 1

	eq(breaches, 0, "value never escaped its bounds across 6000 random operations")
