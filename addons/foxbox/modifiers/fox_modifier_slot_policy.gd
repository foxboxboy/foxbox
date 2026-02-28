class_name FoxModifierSlotPolicy
extends FoxNode
## Acts as a gatekeeper for a [FoxModifierManager], enforcing a maximum limit 
## on how many distinct [FoxModifierInstance] objects can exist simultaneously.


#region Signals

## Emitted whenever the tracked slots change (added, removed, or refreshed).
signal slots_updated(current_slots: Array[FoxModifierInstance])

#endregion


#region Variables

## The maximum number of distinct modifier instances this policy will allow.
@export var max_slots: int = 3

@onready var manager: FoxModifierManager = get_parent()

## The internal array tracking the currently managed instances.
var slots: Array[FoxModifierInstance] = []

#endregion


#region Public API

## Attempts to add a modifier via the Manager, enforcing the slot limit.
## Returns [code]true[/code] if successful.
func try_add(mod: FoxModifier, target: Node) -> bool:
	if not manager:
		push_error("FoxModifierSlotPolicy: No FoxModifierManager parent found.")
		return false
		
	# 1. Let the Manager handle the math, stacking, and instantiation.
	var instance = manager.add_modifier(mod, target)
	
	if not instance: 
		return false
		
	# 2. Check if this is just an existing buff that got stacked/refreshed.
	if slots.has(instance):
		slots_updated.emit(slots)
		return true 
		
	# 3. It's a brand new instance. Enforce the limit.
	if slots.size() >= max_slots:
		_push_out_oldest()
		
	# 4. Add the new instance to the front of the line.
	slots.push_front(instance)
	
	# 5. Listen for natural death (timer ran out) to prevent ghost slots!
	
	slots_updated.emit(slots)
	return true


## Clears all tracked slots and forces the Manager to delete them.
func clear_slots() -> void:
	# Loop backwards to safely pop and destroy
	for i in range(slots.size() - 1, -1, -1):
		var instance = slots[i]
		if is_instance_valid(instance):
			instance.request_destruction.disconnect(_on_slot_destroyed)
			manager.remove_instance(instance)
			
	slots.clear()
	slots_updated.emit(slots)

#endregion


#region Private Logic

func _ready() -> void:
	if manager:
		manager.instance_removed.connect(_on_manager_instance_removed)


func _on_manager_instance_removed(instance: FoxModifierInstance) -> void:
	# If the manager deleted something that we were tracking, remove it from our slots!
	if slots.has(instance):
		slots.erase(instance)
		slots_updated.emit(slots)


func _push_out_oldest() -> void:
	var oldest = slots.pop_back()
	
	if is_instance_valid(oldest):
		# Disconnect our tracking signal so we don't double-erase
		
		# Tell the manager to permanently execute it
		manager.remove_instance(oldest)


func _on_slot_destroyed(instance: FoxModifierInstance) -> void:
	# This triggers if the buff dies naturally (e.g., duration hit 0.0).
	# It ensures the Policy's array stays perfectly synced with the Manager.
	if slots.has(instance):
		slots.erase(instance)
		slots_updated.emit(slots)

#endregion
