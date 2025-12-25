# tates_lib/modifiers/tate_modifier_slot_policy.gd
extends Node
class_name TateModifierSlotPolicy
## Enforces slot limits (e.g., 1 Weapon slot, 3 Upgrade slots).

signal slots_updated(current_slots: Array[TateModifierNode])

@export var max_slots: int = 3
@export var push_out_oldest: bool = true

@onready var manager: TateModifierManager = get_parent()
var slots: Array[TateModifierNode] = []

func try_add(mod: TateModifier, target: Node) -> bool:
	# 1. Ask Manager to process the logic/instantiation
	var node = manager.add_modifier(mod, target)
	if not node: return false
	
	# 2. Update our local tracking (if it's a new instance)
	if not slots.has(node):
		slots.push_front(node)
	
	# 3. Enforce Limit
	if slots.size() > max_slots:
		if push_out_oldest:
			var oldest = slots.pop_back()
			if is_instance_valid(oldest):
				oldest.queue_free()
		else:
			# If we can't push out, we must undo what the manager did
			slots.erase(node)
			node.queue_free()
			return false
			
	slots_updated.emit(slots)
	return true


func clear_modifiers():
	slots.clear()
	slots_updated.emit(slots)
