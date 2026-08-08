class_name PoisonEffect
extends FoxEffect

var damage_per_tick := 5.0

func _init() -> void:
	id = &"deadly_poison"
	stack_mode = StackMode.INTENSITY
	duration_mode = DurationMode.REFRESH
	max_stacks = 3
	duration = 2.0
	tick_interval = 0.5


func _on_execute(target: Object) -> void:
	pass


func _on_reapply(target: Object, current_stack: int = 1) -> void:
	pass


func _on_tick(target: Object, current_stack: int) -> void:
	if target.get("health") != null:
		var damage = current_stack * damage_per_tick
		target.health -= damage
		print("[+] Poison ticks for %s damage! (Stacks: %s) -> [Dummy HP: %.2f]" % [damage, current_stack, target.health])


func _on_remove(target: Object) -> void:
	print("[-] Deadly poison has completely worn off of ", target)
