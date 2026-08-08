extends "res://tests/fox_test.gd"


func run() -> void:
	suite = "stat_pool"
	_defaults()
	_spending_and_refilling()
	_percentage()
	_max_modifiers()
	_lowering_the_max_clamps_current()
	_signals()
	_random_spending_stays_in_range()


func _defaults() -> void:
	case("defaults")
	var p := FoxStatPool.new()
	almost(p.max_value, 100.0, "max comes from base_max")
	almost(p.current, 100.0, "the pool starts full")


func _spending_and_refilling() -> void:
	case("spending")
	var p := FoxStatPool.new()
	p.subtract(30.0)
	almost(p.current, 70.0, "subtract lowers current")
	p.add(10.0)
	almost(p.current, 80.0, "add raises current")

	p.add(9999.0)
	almost(p.current, 100.0, "current cannot exceed the max")

	p.subtract(9999.0)
	almost(p.current, 0.0, "current cannot go below zero")


func _percentage() -> void:
	case("percentage")
	var p := FoxStatPool.new()
	almost(p.get_percent(), 1.0, "a full pool is 1.0")

	p.subtract(75.0)
	almost(p.get_percent(), 0.25, "a quarter full is 0.25")

	p.subtract(25.0)
	almost(p.get_percent(), 0.0, "an empty pool is 0.0")

	case("percentage with no capacity")
	var zero := FoxStatPool.new()
	zero.base_max = 0.0
	almost(zero.get_percent(), 0.0, "a zero maximum returns 0.0 rather than dividing by zero")


func _max_modifiers() -> void:
	case("max modifiers")
	var p := FoxStatPool.new()
	p.add_flat_max_modifier(&"vitality", 50.0)
	almost(p.max_value, 150.0, "a flat modifier raises the max")

	p.add_multiplier_max_modifier(&"blessing", 1.0)
	almost(p.max_value, 300.0, "a multiplier doubles the modified max")

	check(p.pop_flat_max_modifier(&"vitality"), "popping a present modifier reports success")
	almost(p.max_value, 200.0, "the max dropped accordingly")

	check(not p.pop_flat_max_modifier(&"vitality"), "popping again reports failure")

	p.clear_all_max_modifiers()
	almost(p.max_value, 100.0, "clearing returns the max to base_max")

	case("clearing one id")
	var q := FoxStatPool.new()
	q.add_flat_max_modifier(&"a", 10.0)
	q.add_flat_max_modifier(&"b", 20.0)
	q.clear_flat_max_modifier(&"a")
	almost(q.max_value, 120.0, "only the named modifier was cleared")


func _lowering_the_max_clamps_current() -> void:
	case("lowering the max")
	var p := FoxStatPool.new()
	almost(p.current, 100.0, "pool starts full")

	p.base_max = 40.0
	almost(p.max_value, 40.0, "max followed base_max down")
	almost(p.current, 40.0, "current was clamped down with it")

	case("raising the max does not refill")
	p.base_max = 200.0
	almost(p.max_value, 200.0, "max went up")
	almost(p.current, 40.0, "current stayed where it was")


func _signals() -> void:
	case("signals")
	var p := FoxStatPool.new()
	var updates := [0]
	var depleted := [0]
	p.updated.connect(func(_c: float, _m: float) -> void: updates[0] += 1)
	p.depleted.connect(func(_u: float) -> void: depleted[0] += 1)

	p.subtract(10.0)
	check(updates[0] > 0, "spending emits updated")

	p.subtract(9999.0)
	eq(depleted[0], 1, "emptying the pool emits depleted once")


func _random_spending_stays_in_range() -> void:
	case("invariant under random spending")
	var breaches := 0

	for i in 200:
		var p := FoxStatPool.new()
		p.base_max = rng.randf_range(1.0, 500.0)

		for j in 25:
			if rng.randf() < 0.5:
				p.subtract(rng.randf_range(0.0, 100.0))
			else:
				p.add(rng.randf_range(0.0, 100.0))

			if p.current < -0.0001 or p.current > p.max_value + 0.0001:
				breaches += 1

	eq(breaches, 0, "current stayed between zero and max across 5000 random operations")
