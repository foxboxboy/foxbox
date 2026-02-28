extends FoxModifier
class_name FoxDemoModifierWindUpUpgrade

func _on_execute(target: Node) -> void:
	if target is FoxDemoKnight:
		var damage_component : FoxModifiableStat = target.damage_component
		damage_component.add_flat_modifier(modifier_id, 3.0)
		damage_component.add_multiplier_modifier(modifier_id, 0.2)

func _on_remove(target : Node) -> void:
	if target is FoxDemoKnight:
		var damage_component : FoxModifiableStat = target.damage_component
		damage_component.pop_flat_modifier(modifier_id)
		damage_component.pop_multiplier_modifier(modifier_id)


func _on_reapply(_target: Node, _stack: int = 1) -> void:
	pass
