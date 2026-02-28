class_name FoxDemoModifierUpgrade
extends FoxModifier
## A generic stat upgrade. Set stack_mode to INTENSITY in the inspector.

@export var stat_to_modify: StringName = &"speed" # e.g., "speed" or "damage"
@export var flat_bonus: float = 3.0
@export var multiplier_bonus: float = 0.2

func _on_execute(target: Node) -> void:
	_apply_math(target, 1)

func _on_reapply(target: Node, stack: int = 1) -> void:
	# When intensity goes up, re-calculate the math!
	_apply_math(target, stack)

func _on_remove(target: Node) -> void:
	if target is FoxDemoKnight:
		var stat = target.speed_component if stat_to_modify == &"speed" else target.damage_component
		stat.pop_flat_modifier(modifier_id)
		stat.pop_multiplier_modifier(modifier_id)

func _apply_math(target: Node, stack: int) -> void:
	if target is FoxDemoKnight:
		var stat = target.speed_component if stat_to_modify == &"speed" else target.damage_component
		
		# Replace existing math with the newly stacked math
		stat.pop_flat_modifier(modifier_id)
		stat.pop_multiplier_modifier(modifier_id)
		
		stat.add_flat_modifier(modifier_id, flat_bonus * stack)
		stat.add_multiplier_modifier(modifier_id, multiplier_bonus * stack)
