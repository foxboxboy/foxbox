# tates_lib/modifiers/tate_modifier_manager.gd
extends Node
class_name TateModifierManager
## Handles the creation and collision logic of Modifier Nodes.

signal modifiers_updated


## The central point for adding logic to a unit.
func add_modifier(mod_data: TateModifier, target: Node) -> TateModifierNode:
	if not mod_data: return null

	# 1. Check for existing instances by ID (Node Name)
	var existing: TateModifierNode = get_node_or_null(mod_data.modifier_id)
	
	if existing:
		if mod_data.stack_mode == TateModifier.StackMode.UNIQUE:
			existing.time_left = mod_data.duration
			return existing
			
		if mod_data.stack_mode == TateModifier.StackMode.ADDITIVE:
			existing.apply_stack()
			existing.time_left = mod_data.duration
			return existing
			
		# If STACKING, we ignore 'existing' and proceed to create a new one.

	# 2. Create the New Node Instance
	var new_node := TateModifierNode.new()
	new_node.modifier_data = mod_data
	new_node.target = target
	new_node.time_left = mod_data.duration
	
	# Naming logic to prevent "wind_up_2" clutter
	if mod_data.stack_mode == TateModifier.StackMode.STACKING:
		new_node.name = str(mod_data.modifier_id, "_", Time.get_ticks_msec())
	else:
		new_node.name = mod_data.modifier_id
		
	add_child(new_node)
	modifiers_updated.emit()
	return new_node


func remove_modifier_by_id(id: String) -> void:
	var node = get_node_or_null(id)
	if node: node.queue_free()


func remove_all_modifiers():
	for node in get_children():
		if node is TateModifierNode:
			node.queue_free()
		if node is TateModifierSlotPolicy:
			node.clear_modifiers()
