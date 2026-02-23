extends Node

var test_pool: FoxStatPool

func _ready() -> void:
	print("--- RUNNING AUTOMATED MATH TESTS ---")
	_run_tests()
	print("--- ALL TESTS PASSED SUCCESSFULLY! ---")
	
	$Ding.play()
	$Label.show()
	
	# We clean up the test node when we are done
	test_pool.queue_free()

func _run_tests() -> void:
	# Setup
	test_pool = FoxStatPool.new()
	test_pool.base_max = 100.0
	add_child(test_pool) 
	
	# --- TEST 1: RAW DAMAGE & CLAMPING ---
	test_pool.subtract(30.0)
	assert(is_equal_approx(test_pool.current, 70.0), "TEST FAILED: Basic subtraction is broken.")
	
	test_pool.add(50.0)
	assert(is_equal_approx(test_pool.current, 100.0), "TEST FAILED: Value exceeded max bounds.")
	
	test_pool.subtract(150.0)
	assert(is_equal_approx(test_pool.current, 0.0), "TEST FAILED: Value dropped below 0.")

	# --- TEST 2: MAX STAT MODIFIERS ---
	test_pool.current = 100.0 
	var stats = test_pool.max_stat
	
	stats.add_modifier("giant_belt", FoxModifiableStat.ModifierType.FLAT, 50.0)
	assert(is_equal_approx(stats.value, 150.0), "TEST FAILED: Flat addition is broken.")
	
	stats.add_modifier("iron_potion", FoxModifiableStat.ModifierType.FLAT, 20.0)
	assert(is_equal_approx(stats.value, 170.0), "TEST FAILED: Stacking flat modifiers is broken.")
	
	stats.add_modifier("vitality_ring", FoxModifiableStat.ModifierType.MULTIPLIER, 0.5)
	assert(is_equal_approx(stats.value, 255.0), "TEST FAILED: Multiplier logic is broken.")

	# --- TEST 3: MODIFIER REMOVAL & STACKING ---
	stats.add_modifier("iron_potion", FoxModifiableStat.ModifierType.FLAT, 20.0)
	assert(is_equal_approx(stats.value, 285.0), "TEST FAILED: Identical ID stacking is broken.")
	
	stats.clear_modifier("iron_potion", FoxModifiableStat.ModifierType.FLAT)
	assert(is_equal_approx(stats.value, 225.0), "TEST FAILED: clear_modifier did not remove all instances.")
	
	stats.pop_modifier("giant_belt", FoxModifiableStat.ModifierType.FLAT)
	assert(is_equal_approx(stats.value, 150.0), "TEST FAILED: pop_modifier failed to remove flat stat.")
	
	stats.pop_modifier("vitality_ring", FoxModifiableStat.ModifierType.MULTIPLIER)
	assert(is_equal_approx(stats.value, 100.0), "TEST FAILED: pop_modifier failed to remove multiplier stat.")
	
	# --- TEST 4: SPECIFIC VALUE REMOVAL ---
	stats.add_modifier("weird_curse", FoxModifiableStat.ModifierType.FLAT, -10.0)
	stats.add_modifier("weird_curse", FoxModifiableStat.ModifierType.FLAT, -5.0)
	stats.remove_specific_modifier("weird_curse", FoxModifiableStat.ModifierType.FLAT, -10.0)
	assert(is_equal_approx(stats.value, 95.0), "TEST FAILED: remove_specific_modifier removed the wrong float.")
