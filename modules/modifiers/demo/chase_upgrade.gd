extends TateModifier
class_name ChaseUpgrade

func execute(target: Node) -> void:
	var speed_stat : TateModifiableStat = target.stats_component.speed_stat
	speed_stat.add_flat_modifier("chase", 3.0)
