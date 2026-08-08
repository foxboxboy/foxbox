extends Node

@export var test_pool: FoxStatPool


func _ready() -> void:
	print("--- RUNNING AUTOMATED MATH TESTS ---")
	_run_tests()
	print("--- ALL TESTS PASSED SUCCESSFULLY! ---")
	
	$Ding.play()
	$Label.show()
	
	# Resources are reference-counted. Setting it to null 
	# automatically clears it from memory!
	test_pool = null


func _run_tests() -> void:
	# Setup
	test_pool = FoxStatPool.new()
	test_pool.base_max = 100.0
	
	# --- TEST 1: RAW DAMAGE & CLAMPING ---
	test_pool.subtract(30.0)
	assert(is_equal_approx(test_pool.current, 70.0), "TEST FAILED: Basic subtraction is broken.")
	
	test_pool.add(50.0)
	assert(is_equal_approx(test_pool.current, 100.0), "TEST FAILED: Value exceeded max bounds.")
	
	test_pool.subtract(150.0)
	assert(is_equal_approx(test_pool.current, 0.0), "TEST FAILED: Value dropped below 0.")

	# --- TEST 2: MAX STAT MODIFIERS ---
	test_pool.current = 100.0 
	
	test_pool.add_max_modifier("giant_belt", FoxModifiableStat.ModifierType.FLAT, 50.0)
	assert(is_equal_approx(test_pool.max_value, 150.0), "TEST FAILED: Flat addition is broken.")
	
	test_pool.add_max_modifier("iron_potion", FoxModifiableStat.ModifierType.FLAT, 20.0)
	assert(is_equal_approx(test_pool.max_value, 170.0), "TEST FAILED: Stacking flat modifiers is broken.")
	
	test_pool.add_max_modifier("vitality_ring", FoxModifiableStat.ModifierType.MULTIPLIER, 0.5)
	assert(is_equal_approx(test_pool.max_value, 255.0), "TEST FAILED: Multiplier logic is broken.")

	# --- TEST 3: MODIFIER REMOVAL & STACKING ---
	test_pool.add_max_modifier("iron_potion", FoxModifiableStat.ModifierType.FLAT, 20.0)
	assert(is_equal_approx(test_pool.max_value, 285.0), "TEST FAILED: Identical ID stacking is broken.")
	
	test_pool.clear_max_modifier("iron_potion", FoxModifiableStat.ModifierType.FLAT)
	assert(is_equal_approx(test_pool.max_value, 225.0), "TEST FAILED: clear_max_modifier did not remove all instances.")
	
	test_pool.pop_max_modifier("giant_belt", FoxModifiableStat.ModifierType.FLAT)
	assert(is_equal_approx(test_pool.max_value, 150.0), "TEST FAILED: pop_max_modifier failed to remove flat stat.")
	
	test_pool.pop_max_modifier("vitality_ring", FoxModifiableStat.ModifierType.MULTIPLIER)
	assert(is_equal_approx(test_pool.max_value, 100.0), "TEST FAILED: pop_max_modifier failed to remove multiplier stat.")
	
	# --- TEST 4: SPECIFIC VALUE REMOVAL ---
	test_pool.add_max_modifier("weird_curse", FoxModifiableStat.ModifierType.FLAT, -10.0)
	test_pool.add_max_modifier("weird_curse", FoxModifiableStat.ModifierType.FLAT, -5.0)
	
	# Accessing the internal engine here since this is a highly specific edge-case removal
	test_pool._max_stat.remove_specific_modifier("weird_curse", FoxModifiableStat.ModifierType.FLAT, -10.0)
	assert(is_equal_approx(test_pool.max_value, 95.0), "TEST FAILED: remove_specific_modifier removed the wrong float.")
