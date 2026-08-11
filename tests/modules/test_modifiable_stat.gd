extends FoxTest


func run() -> void:
	suite = "modifiable_stat"
	_base_value()
	_flat_modifiers()
	_multiplier_is_one_plus_sum()
	_combined_order_of_operations()
	_popping()
	_clearing()
	_has_modifier()
	_remove_specific()
	_change_signal_only_fires_on_change()
	_random_stacks_match_the_formula()


func _base_value() -> void:
	start_case("base value")
	var s: FoxModifiableStat = FoxModifiableStat.new(10.0)
	check_almost_equal(s.value, 10.0, "value starts at base")
	s.base_value = 25.0
	check_almost_equal(s.value, 25.0, "changing base recalculates")


func _flat_modifiers() -> void:
	start_case("flat modifiers")
	var s: FoxModifiableStat = FoxModifiableStat.new(10.0)
	s.add_flat_modifier(&"boots", 5.0)
	check_almost_equal(s.value, 15.0, "one flat modifier adds")
	s.add_flat_modifier(&"ring", 2.0)
	check_almost_equal(s.value, 17.0, "flat modifiers accumulate across ids")
	s.add_flat_modifier(&"boots", 3.0)
	check_almost_equal(s.value, 20.0, "the same id stacks rather than replacing")


## The class doc used to say the total was multiplied by the SUM of the multipliers.
## It is multiplied by 1.0 plus that sum, so 0.5 means +50%, not half.
func _multiplier_is_one_plus_sum() -> void:
	start_case("multiplier semantics")
	var s: FoxModifiableStat = FoxModifiableStat.new(100.0)
	s.add_multiplier_modifier(&"rage", 0.5)
	check_almost_equal(s.value, 150.0, "a 0.5 multiplier means +50 percent")

	s.clear_all_modifiers()
	s.add_multiplier_modifier(&"a", 0.5)
	s.add_multiplier_modifier(&"b", 0.5)
	check_almost_equal(s.value, 200.0, "two 0.5 multipliers stack additively to +100 percent")

	s.clear_all_modifiers()
	s.add_multiplier_modifier(&"debuff", -0.25)
	check_almost_equal(s.value, 75.0, "a negative multiplier reduces the total")


func _combined_order_of_operations() -> void:
	start_case("flat applies before multiplier")
	var s: FoxModifiableStat = FoxModifiableStat.new(100.0)
	s.add_flat_modifier(&"gear", 50.0)
	s.add_multiplier_modifier(&"buff", 1.0)
	check_almost_equal(s.value, 300.0, "(100 + 50) * 2.0 rather than 100 + (50 * 2.0)")


func _popping() -> void:
	start_case("popping")
	var s: FoxModifiableStat = FoxModifiableStat.new(0.0)
	s.add_flat_modifier(&"stack", 1.0)
	s.add_flat_modifier(&"stack", 10.0)
	check_almost_equal(s.value, 11.0, "two entries under one id")

	var popped: bool = s.pop_modifier(&"stack", FoxModifiableStat.ModifierType.FLAT)
	check(popped, "pop reports success")
	check_almost_equal(s.value, 1.0, "pop removes the most recent entry, not the first")

	s.pop_modifier(&"stack", FoxModifiableStat.ModifierType.FLAT)
	check_almost_equal(s.value, 0.0, "popping the last entry empties the stack")

	var missing: bool = s.pop_modifier(&"stack", FoxModifiableStat.ModifierType.FLAT)
	check(not missing, "popping an empty stack reports failure")

	var never: bool = s.pop_modifier(&"nonexistent", FoxModifiableStat.ModifierType.FLAT)
	check(not never, "popping an unknown id reports failure")


func _clearing() -> void:
	start_case("clearing")
	var s: FoxModifiableStat = FoxModifiableStat.new(10.0)
	s.add_flat_modifier(&"poison", 1.0)
	s.add_flat_modifier(&"poison", 1.0)
	s.add_flat_modifier(&"keep", 5.0)

	s.clear_modifier(&"poison", FoxModifiableStat.ModifierType.FLAT)
	check_almost_equal(s.value, 15.0, "clear removes every entry under that id only")

	s.clear_all_modifiers()
	check_almost_equal(s.value, 10.0, "clear_all returns the stat to its base value")


func _has_modifier() -> void:
	start_case("has_modifier")
	var s: FoxModifiableStat = FoxModifiableStat.new(0.0)
	check(not s.has_modifier(&"x", FoxModifiableStat.ModifierType.FLAT), "unknown id is absent")

	s.add_flat_modifier(&"x", 1.0)
	check(s.has_modifier(&"x", FoxModifiableStat.ModifierType.FLAT), "added id is present")
	check(not s.has_modifier(&"x", FoxModifiableStat.ModifierType.MULTIPLIER),
		"types are tracked separately")

	s.pop_modifier(&"x", FoxModifiableStat.ModifierType.FLAT)
	check(not s.has_modifier(&"x", FoxModifiableStat.ModifierType.FLAT),
		"an emptied stack is erased, so has_modifier goes false")


func _remove_specific() -> void:
	start_case("remove_specific_modifier")
	var s: FoxModifiableStat = FoxModifiableStat.new(0.0)
	s.add_flat_modifier(&"mix", 1.0)
	s.add_flat_modifier(&"mix", 7.0)
	s.add_flat_modifier(&"mix", 3.0)

	var hit: bool = s.remove_specific_modifier(&"mix", FoxModifiableStat.ModifierType.FLAT, 7.0)
	check(hit, "removing an existing amount reports success")
	check_almost_equal(s.value, 4.0, "only the matching amount was removed")

	var miss: bool = s.remove_specific_modifier(&"mix", FoxModifiableStat.ModifierType.FLAT, 99.0)
	check(not miss, "removing an absent amount reports failure")
	check_almost_equal(s.value, 4.0, "a failed removal changes nothing")


func _change_signal_only_fires_on_change() -> void:
	start_case("value_changed")
	var s: FoxModifiableStat = FoxModifiableStat.new(10.0)
	var count: Array[int] = [0]
	s.value_changed.connect(func(_v: float) -> void: count[0] += 1)

	s.add_flat_modifier(&"a", 5.0)
	check_equal(count[0], 1, "a real change emits once")

	s.add_flat_modifier(&"b", 0.0)
	check_equal(count[0], 1, "a modifier that does not move the number stays silent")


func _random_stacks_match_the_formula() -> void:
	start_case("invariant against the documented formula")
	var mismatches: int = 0

	for i: int in 200:
		var base: float = rng.randf_range(-100.0, 100.0)
		var s: FoxModifiableStat = FoxModifiableStat.new(base)
		var flats: float = 0.0
		var mults: float = 0.0

		for j: int in 12:
			var amount: float = rng.randf_range(-5.0, 5.0)
			if rng.randf() < 0.5:
				s.add_flat_modifier(&"f", amount)
				flats += amount
			else:
				s.add_multiplier_modifier(&"m", amount)
				mults += amount

		var expected: float = (base + flats) * (1.0 + mults)
		if absf(s.value - expected) > 0.001:
			mismatches += 1

	check_equal(mismatches, 0, "(base + flats) * (1 + mults) held for 200 random stacks")
