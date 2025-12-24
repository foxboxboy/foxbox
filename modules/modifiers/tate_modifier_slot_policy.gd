# tates_lib/modifiers/tate_modifier_slot_policy.gd
extends TateComponent
class_name TateModifierSlotPolicy
## Manages a limited number of slots for modifiers on a target.

signal slots_updated(current_slots: Array[TateModifierNode])

@export var max_slots: int = 3
## If true, adding a new modifier when full removes the oldest one.
## If false, it rejects the new modifier.
@export var push_out_oldest: bool = true

@onready var manager: TateModifierManager = get_parent() # Usually attached to the manager

var slots: Array[TateModifierNode] = []

## Returns true if successful. Returns false if a modifier
## couldn't be added.
func add_modifier(mod: TateModifier, target: Node) -> bool:
	if mod == null:
		printerr("ERROR: mod is empty under add_modifier in TateModifierSlotPolicy ",get_path())
	
	var new_modifier_node := TateModifierNode.new()
	new_modifier_node.modifier_data = mod
	
	slots.push_front(new_modifier_node)
	manager.add_modifier(new_modifier_node, target)
	
	
	if slots.size() > max_slots:
		if not push_out_oldest:
			return false
		# Remove oldest
		var oldest = slots.pop_back()
		manager.remove_modifier(oldest)
		
	slots_updated.emit(slots)
	
	return true
