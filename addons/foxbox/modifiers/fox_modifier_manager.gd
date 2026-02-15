# tates_lib/modifiers/tate_modifier_manager.gd
extends FoxNode
class_name FoxModifierManager
## Handles the creation, lifetime, and cleanup of Modifier Instances.
## REFACTOR NOTE: Now uses an internal Array instead of child Nodes for performance.

## Emitted when a FoxModifierInstance is added or removed.
signal modifiers_updated

# CHANGED: We store data objects, not child nodes
var active_modifiers: Array[FoxModifierInstance] = []

func _process(delta: float) -> void:
	# We loop backwards so we can safely remove items while iterating
	for i in range(active_modifiers.size() - 1, -1, -1):
		var instance = active_modifiers[i]
		
		# -1 duration means "Permanent" (Infinite)
		if instance.time_left != -1:
			instance.time_left -= delta
			
			if instance.time_left <= 0:
				_remove_instance_at(i)


## Returns the FoxModifierInstance that was added. If tate_modifier is null returns null. 
## Depending on the stack_mode of the FoxModifier, different things happen.
## Both StackMode.SINGLE & StackMode.ADDITIVE allow only one FoxModifierInstance
## to exist in this manager with that associated FoxModifier.
## StackMode.UNIQUE checks for an existing FoxModifierInstance
## and updates its duration to match. 
## StackMode.ADDITIVE runs FoxModifierInstance.increase_stack(). 
## Increasing its stack by 1 and telling its FoxModifier to run reapply().
## StackMode.MULTIPLE_INSTANCES makes a new FoxModifierInstance with a unique suffix
## (handled automatically by being a distinct object in the Array).
func add_modifier(tate_modifier: FoxModifier, target: Node) -> FoxModifierInstance:
	print("add_modifier ",tate_modifier.modifier_id)
	
	if not tate_modifier: return null

	# 1. Check for existing instances by ID
	var existing: FoxModifierInstance = _get_instance_by_id(tate_modifier.modifier_id)
	
	if existing:
		if tate_modifier.stack_mode == FoxModifier.StackMode.UNIQUE:
			existing.time_left = tate_modifier.duration
			return existing
			
		if tate_modifier.stack_mode == FoxModifier.StackMode.ADDITIVE:
			existing.increase_stack()
			existing.time_left = tate_modifier.duration
			return existing
			
		# StackMode.MULTIPLE_INSTANCES falls through to create a new one below

	# make a new FoxModifierInstance if there wasn't an existing instance 
	var new_instance := FoxModifierInstance.new()
	new_instance.modifier_data = tate_modifier
	new_instance.target = target
	new_instance.time_left = tate_modifier.duration
	
	# Execute the logic immediately (Replaces _ready)
	tate_modifier.execute(target)
	
	# Store it
	active_modifiers.append(new_instance)
	modifiers_updated.emit()
	
	return new_instance


## Removes a FoxModifierInstance associated with a modifier_id.
## Set all_instances to true to delete all FoxModifierInstances
## associated with that modifier_id.
func remove_modifier_by_id(modifier_id: StringName, all_instances := false) -> void:
	# Loop backwards to find and destroy
	for i in range(active_modifiers.size() - 1, -1, -1):
		if active_modifiers[i].modifier_id == modifier_id:
			_remove_instance_at(i)
			if not all_instances:
				return # We removed one, job done


## Removes a specific instance object.
func remove_instance(instance: FoxModifierInstance) -> void:
	var idx = active_modifiers.find(instance)
	if idx != -1:
		_remove_instance_at(idx)


## Removes all FoxModifierInstances under this FoxModifierManager.
## Cleans up/resets any FoxModifierSlotPolicy under this FoxModifierManager too.
func remove_all_modifiers():
	# Loop backwards clearing everything
	for i in range(active_modifiers.size() - 1, -1, -1):
		_remove_instance_at(i)
		
	# Also clear policy slots if you have them
	for child in get_children():
		if child is FoxModifierSlotPolicy:
			child.clear_slots()

# --- Internal Helpers ---

func _get_instance_by_id(id: StringName) -> FoxModifierInstance:
	for instance in active_modifiers:
		if instance.modifier_id == id:
			return instance
	return null

func _remove_instance_at(index: int):
	var instance = active_modifiers[index]
	
	# Important: We must manually trigger the cleanup logic!
	# (Since there is no _exit_tree)
	instance.cleanup()
	
	active_modifiers.remove_at(index)
	modifiers_updated.emit()
