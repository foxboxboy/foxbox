extends TateModifier
class_name TateDemoModifierChaseUpgrade

func _on_execute(target: Node) -> void:
	if target is TateDemoKnight:
		var speed_component : TateModifiableStat = target.speed_component
		speed_component.add_flat_modifier(modifier_id, 3.0)
		speed_component.add_multiplier_modifier(modifier_id, 0.2)


func _on_remove(target : Node) -> void:
	if target is TateDemoKnight:
		var speed_component : TateModifiableStat = target.speed_component
		speed_component.remove_flat_modifier(modifier_id)
		speed_component.remove_multiplier_modifier(modifier_id)
