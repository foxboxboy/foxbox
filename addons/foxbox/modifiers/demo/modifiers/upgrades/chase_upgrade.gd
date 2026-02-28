extends FoxModifier
class_name FoxDemoModifierChaseUpgrade

func _on_execute(target: Node) -> void:
	if target is FoxDemoKnight:
		var speed_component : FoxModifiableStat = target.speed_component
		speed_component.add_flat_modifier(modifier_id, 3.0)
		speed_component.add_multiplier_modifier(modifier_id, 0.2)


func _on_remove(target : Node) -> void:
	if target is FoxDemoKnight:
		var speed_component : FoxModifiableStat = target.speed_component
		speed_component.pop_flat_modifier(modifier_id)
		speed_component.pop_multiplier_modifier(modifier_id)


func _on_reapply(_target: Node, _stack: int = 1) -> void:
	pass
