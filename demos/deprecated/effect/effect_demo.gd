extends Node

var manager: FoxEffectManager
const DummyData = preload("uid://c1n7lj4kr70nq")
const PoisonSpell = preload("uid://bpkfk8k61s1sk")

func _ready() -> void:
	manager = FoxEffectManager.new()
	add_child(manager)

	var dummy = DummyData.new()
	var poison = PoisonSpell.new()

	print("=== COMBAT START ===")
	print("Initial State: ", dummy)

	await get_tree().create_timer(0.5).timeout
	print("\n>>> Turn 1: Casting Poison...")
	manager.add_effect(poison, dummy)
	print(manager.effects)

	await get_tree().create_timer(1.0).timeout
	print("\n>>> Turn 2: Casting Poison again (Should Stack & Refresh Timer)")
	manager.add_effect(poison, dummy)
	print(manager.effects)

	await get_tree().create_timer(3.5).timeout
	print("\n=== COMBAT END ===")
	print("Final State: ", dummy)
	print("Active Effects Remaining: ", manager.effects.size())
