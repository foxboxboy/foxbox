# project/modifiers/health_upgrade_modifier.gd
extends FoxModifier
class_name FoxDemoModifierHealthUpgrade

@export var health_bonus: float = 5.0

func _on_execute(target: Node) -> void:
	# 1. Find the physical 'Address' in the Logic folder
	var health_node
	
	if target is FoxDemoKnight:
		health_node = target.health_component
	
	if health_node is FoxStatPool:
		# 2. Add the bonus to the MAX engine
		# We use the ModifierNode's name or ID as the unique key
		health_node.add_flat_max_modifier(modifier_id, health_bonus)
		
		# 3. Optional: Heal the player for the amount gained so it doesn't just look like 
		# an empty extension of the health bar.
		health_node.add(health_bonus)

func _on_remove(target: Node) -> void:
	var health_node
	
	if target is FoxDemoKnight:
		health_node = target.health_component
	
	if health_node is FoxStatPool:
		# Remove the specific bonus using the ID
		health_node.pop_flat_max_modifier(modifier_id)


func _on_reapply(_target: Node, _stack: int = 1) -> void:
	pass
