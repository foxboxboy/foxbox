# tates_lib/modifiers/tate_modifier_slot_policy.gd

## WARNING for dev you might wanna come back and check
## the try_add function it could lead to some funky behaviour
## since when we add a new policy slot it straight up kills
## the whole modifier instance
## this won't make sense to literally anyone else reading this
## and it probably won't make sense to me in 1 week but if you
## have some dumb weird behavior with the slots investigate there 

extends TateComponent
class_name TateModifierSlotPolicy
## Handles "slots" in a TateModifierManager 
## (ex: 1 Weapon slot, 3 Upgrade slots).

## Emitted when the slots change.
signal slots_updated(current_slots: Array[TateModifierInstance])

## How many TateModifierInstances this SlotPolicy can have.
@export var max_slots: int = 3
## Turn to false to make this policy not remove, then add when calling try_add().
## It will only remove, then once try_add() is called again add. 
#@export var push_out_oldest: bool = true

@onready var manager: TateModifierManager = get_parent()
var slots: Array[TateModifierInstance] = []

## Returns fale if a slot couldn't be added.
func try_add(mod: TateModifier, target: Node) -> bool:
	# yell at the manager to add a new modifier.
	# it handles all the stacking, unique, and additive
	# logic stuff
	var node = manager.add_modifier(mod, target)
	
	# uh this shouldn't ever happen
	if not node: 
		push_error("ERROR: a TateModifierInstance couldn't be found\
		under try_add() in TateModifierSlotPolicy ",get_path())
		return false
	
	# update our local tracking (if it's a new instance)
	if not slots.has(node):
		slots.push_front(node)
	
	# limit enforcing (get rid of the oldest modifier instance)
	if slots.size() > max_slots:
		#if push_out_oldest:
		var oldest = slots.pop_back()
		if is_instance_valid(oldest):
			oldest.queue_free()
		#else:
			# If we can't push out, we must undo what the manager did
		#	slots.erase(node)
		#	node.queue_free()
		#	return false
	
	slots_updated.emit(slots)
	return true


## Clears all the slots.
func clear_slots():
	slots.clear()
	slots_updated.emit(slots)
