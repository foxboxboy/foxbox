extends TateModifier
class_name TateDemoModifierChaseUpgrade

func _on_execute(target: Node) -> void:
	if target is TateDemoKnight:
		var speed_stat : TateModifiableStat = target.speed_component
		speed_stat.add_flat_modifier("chase", 3.0)
		speed_stat.add_multiplier_modifier("chase", 0.2)


func _on_remove(target : Node) -> void:
	if target is TateDemoKnight:
		var speed_stat : TateModifiableStat = target.speed_component
		speed_stat.remove_flat_modifier("chase")
		speed_stat.remove_multiplier_modifier("chase")
