# tates_lib/modifiers/tate_modifier_manager.gd
extends Node
class_name TateModifierManager
## Handles the creation and collision logic of Modifier Nodes.

## Emitted when a TateModifierInstance is added or removed as a child of this.
signal modifiers_updated


## Returns the TateModifierInstance that was added. If tate_modifier is null returns null. 
## Depending on the stack_mode of the TateModifier, different things happen.
## Both StackMode.UNIQUE & StackMode.ADDITIVE allow only one TateModifierInstance
## to exist as a child of this TateModifierManager with that associated TateModifier.
## StackMode.UNIQUE checks for an existing TateModifierInstance
## child and updates its duration to match. 
## StackMode.ADDITIVE runs TateModifierInstance.apply_stack(). 
## Increasing its stack by 1 and telling its TateModifier to run reapply().
## StackMode.STACKING makes a new TateModifierInstance with a unique suffix
## then makes it a child of this TateModifierManager.
func add_modifier(tate_modifier: TateModifier, target: Node) -> TateModifierInstance:
	if not tate_modifier: return null

	# 1. Check for existing instances by ID (Node Name)
	var existing: TateModifierInstance = get_node_or_null(NodePath(tate_modifier.modifier_id))
	
	if existing:
		if tate_modifier.stack_mode == TateModifier.StackMode.UNIQUE:
			existing.time_left = tate_modifier.duration
			return existing
			
		if tate_modifier.stack_mode == TateModifier.StackMode.ADDITIVE:
			existing.apply_stack()
			existing.time_left = tate_modifier.duration
			return existing
			
		# If STACKING, we ignore 'existing' and proceed to create a new one.

	# 2. Create the New Node Instance
	var new_node := TateModifierInstance.new()
	new_node.modifier_data = tate_modifier
	new_node.target = target
	new_node.time_left = tate_modifier.duration
	
	# Naming logic to prevent "[modifier_name]_2" clutter
	if tate_modifier.stack_mode == TateModifier.StackMode.STACKING:
		new_node.name = str(tate_modifier.modifier_id, "_", Time.get_ticks_msec())
	else:
		new_node.name = tate_modifier.modifier_id
		
	add_child(new_node)
	modifiers_updated.emit()
	return new_node


## Removes a TateModifierInstance associated with a modifier_id.
## Set all_instances to true to delete all TateModifierInstances
## associated with that modifier_id.
func remove_modifier_by_id(modifier_id: NodePath, all_instances := false) -> void:
	for child in get_children():
		if child is TateModifierInstance:
			if child.modifier_id == modifier_id:
				child.queue_free()
				
				if all_instances == false:
					return


## Removes all TateModifierInstances under this TateModifierManager.
## Cleans up/resets any TateModifierSlotPolicy under this TateModifierManager too.
func remove_all_modifiers():
	for child in get_children():
		if child is TateModifierInstance:
			child.queue_free()
		if child is TateModifierSlotPolicy:
			child.clear_slots()
