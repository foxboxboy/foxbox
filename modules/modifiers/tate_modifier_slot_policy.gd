# tates_lib/core/modifiers/tate_modifier_slot_policy.gd
extends TateComponent
class_name TateModifierSlotPolicy
## Manages a limited number of slots for modifiers on a target.

signal slots_updated(current_slots: Array[TateModifier])

@export var max_slots: int = 3
## If true, adding a new modifier when full removes the oldest one.
## If false, it rejects the new modifier.
@export var push_out_oldest: bool = true

@onready var manager: TateModifierManager = get_parent() # Usually attached to the manager

var slots: Array[TateModifier] = []

## Returns true if successful. Returns false if a modifier
## couldn't be added.
func add_modifier(mod: TateModifier, target: Node) -> bool:
	if slots.size() >= max_slots:
		if not push_out_oldest:
			return false
		# Remove oldest
		var oldest = slots.pop_front()
		manager.remove_modifier(oldest.modifier_id)
	
	slots.append(mod)
	manager.add_modifier(mod, target)
	slots_updated.emit(slots)
	return true
