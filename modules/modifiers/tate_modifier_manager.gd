# tates_lib/modifiers/tate_modifier_manager.gd
extends Node
class_name TateModifierManager
## Handles the addition, removal, and collision of TateModifierNodes.

## Signal for UI to listen to for updating buff bars/icons.
signal modifiers_updated

## Adds a modifier to the target unit.
func add_modifier(new_modifier_node: TateModifierNode, target: Node) -> void:
	if new_modifier_node == null:
		printerr("ERROR: new_modifier_node is empty under add_modifier in TateModifierManager ",get_path())
	
	var modifier_data := new_modifier_node.modifier_data
	
	# 1. Check for 'UNIQUE' collisions
	if modifier_data.stack_mode == TateModifier.StackMode.UNIQUE:
		var existing = get_node_or_null(modifier_data.modifier_id)
		if existing:
			# Refresh timer and stop
			existing.time_left = modifier_data.duration
			return

	# 2. Check for 'ADDITIVE' collisions
	if modifier_data.stack_mode == TateModifier.StackMode.ADDITIVE:
		var existing = get_node_or_null(modifier_data.modifier_id)
		if existing:
			# Custom logic to "power up" existing mod
			existing.modifier_data.on_reapply(target)
			existing.time_left = modifier_data.duration
			return

	# 3. Create the new Node Instance (for STACKING or New UNIQUEs)
	#var new_node : = TateModifierNode.new()
	
	# Configure the node before it enters the tree
	#new_node.modifier_data = mod_data
	new_modifier_node.target = target
	new_modifier_node.time_left = modifier_data	.duration
	
	# Use modifier_id as node name for easy lookup
	# For stacking, we add a timestamp to keep the name unique
	#if mod_data.stack_mode == TateModifier.StackMode.STACKING:
	#	new_node.name = str(mod_data.modifier_id, "_", Time.get_ticks_msec())
	#else:
	#new_node.name = mod_data.modifier_id
		
	add_child(new_modifier_node)
	modifiers_updated.emit()

## Forces removal of a specific modifier.
func remove_modifier(modifier_node: TateModifierNode) -> void:
	modifier_node.queue_free() # Triggers _exit_tree cleanup
	modifiers_updated.emit()

func remove_all_modifiers():
	for node in get_children():
		if node is TateModifierNode:
			node.queue_free()
