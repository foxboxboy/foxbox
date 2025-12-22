extends Node

@export var test_stat : ModifiableStat = ModifiableStat.new()

func _ready() -> void:
	test_stat.add_flat_modifier("extra_health", 1.0)
	test_stat.add_flat_modifier("extra_health", 3.0)
	test_stat.add_flat_modifier("extra_health", 3.0)
	test_stat.add_flat_modifier("jump_boost", 1.0)
	
	test_stat.add_multiplier_modifier("jump_boost_percent", 0.5)
	test_stat.add_multiplier_modifier("jump_boost_percent", 3.5)
	test_stat.add_multiplier_modifier("jump_boost_percent", 0.5)
	
	print("current: ",test_stat.multiplier_modifiers)


func _process(_delta: float) -> void:
	
	var thing = (test_stat.remove_multiplier_modifier("jump_boost_percent",true, 0.5))
	
	if thing is Array:
		print("current: ",test_stat.multiplier_modifiers)
		print("thing...", thing)
	elif thing is float:
		if not is_nan(thing):
			print("current: ",test_stat.multiplier_modifiers)
			print("thing...", thing)
	#print("THING: ",thing)
