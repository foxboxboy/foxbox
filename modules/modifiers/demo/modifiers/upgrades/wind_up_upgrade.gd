extends TateModifier
class_name TateDemoModifierWindUpUpgrade

func _on_execute(target: Node) -> void:
	if target is TateDemoKnight:
		var damage_component : TateModifiableStat = target.damage_component
		damage_component.add_flat_modifier("wind_up", 3.0)
		damage_component.add_multiplier_modifier("wind_up", 0.2)

func _on_remove(target : Node) -> void:
	if target is TateDemoKnight:
		var damage_component : TateModifiableStat = target.damage_component
		damage_component.remove_flat_modifier("wind_up")
		damage_component.remove_multiplier_modifier("wind_up")
