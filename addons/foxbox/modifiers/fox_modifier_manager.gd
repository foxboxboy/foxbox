class_name FoxModifierManager
extends FoxNode
## Handles the creation, lifecycle, and cleanup of [FoxModifierInstance] objects.


#region Signals

## Emitted whenever a [FoxModifierInstance] is added or removed from the active list.
signal modifiers_updated
## Emitted whenever a [FoxModifierInstance] is permanently removed.
signal instance_removed(instance: FoxModifierInstance)

#endregion


#region Variables

## The internal list of currently active modifier instances.
var active_modifiers: Array[FoxModifierInstance] = []

#endregion


#region Built-In Loops

func _process(delta: float) -> void:
	# We loop backwards. If process_time() triggers a destruction signal, 
	# the array size shrinks safely without skipping the next element.
	for i in range(active_modifiers.size() - 1, -1, -1):
		active_modifiers[i].process_time(delta)

#endregion


#region Public API

## Adds a [FoxModifier] to the target. Depending on the [member FoxModifier.stack_mode], 
## this will either return an existing instance or instantiate a new one.
func add_modifier(mod: FoxModifier, target: Node) -> FoxModifierInstance:
	if not mod: return null

	# 1. Check for existing instances by ID
	var existing: FoxModifierInstance = _get_instance_by_id(mod.modifier_id)
	
	print(mod._get_resource_name())
	print(FoxModifier.StackMode.UNIQUE == mod.stack_mode)
	
	if existing:
		if mod.stack_mode == FoxModifier.StackMode.UNIQUE:
			_add_duration(existing, mod.duration)
			return existing
			
		if mod.stack_mode == FoxModifier.StackMode.INTENSITY:
			_add_duration(existing, mod.duration)
			existing.increase_stack(1)
			return existing
			
		# StackMode.MULTIPLE_INSTANCES falls through to create a new one below

	# 2. Instantiate new if no valid existing instance was found
	var new_instance := FoxModifierInstance.new()
	new_instance.modifier_data = mod
	new_instance.target = target
	new_instance.time_left = mod.duration
	
	# Wire up the destruction signal so it can kill itself if stack/time hits 0
	new_instance.request_destruction.connect(_on_instance_request_destruction)
	
	# Execute initial logic
	mod.execute(target)
	
	active_modifiers.append(new_instance)
	modifiers_updated.emit()
	
	return new_instance


## Removes a specific instance object, running its cleanup logic.
func remove_instance(instance: FoxModifierInstance) -> void:
	var idx = active_modifiers.find(instance)
	if idx != -1:
		_remove_instance_at(idx)


## Removes all instances associated with a specific [member FoxModifier.modifier_id].
func remove_modifier_by_id(target_id: StringName, all_instances: bool = false) -> void:
	# Loop backwards to safely remove while iterating
	for i in range(active_modifiers.size() - 1, -1, -1):
		if active_modifiers[i].modifier_id == target_id:
			_remove_instance_at(i)
			if not all_instances:
				return


## Clears every active modifier and runs their cleanup logic.
func remove_all_modifiers() -> void:
	for i in range(active_modifiers.size() - 1, -1, -1):
		_remove_instance_at(i)

#endregion


#region Private Logic

func _add_duration(instance: FoxModifierInstance, added_time: float) -> void:
	# Ignore if either the existing buff or the incoming buff is permanent
	if instance.time_left != -1.0 and added_time != -1.0:
		instance.time_left += added_time


func _get_instance_by_id(target_id: StringName) -> FoxModifierInstance:
	for instance in active_modifiers:
		if instance.modifier_id == target_id:
			return instance
	return null


func _remove_instance_at(index: int) -> void:
	var instance = active_modifiers[index]
	
	instance.request_destruction.disconnect(_on_instance_request_destruction)
	instance.cleanup()
	
	active_modifiers.remove_at(index)
	
	instance_removed.emit(instance)
	modifiers_updated.emit()


func _on_instance_request_destruction(instance: FoxModifierInstance) -> void:
	remove_instance(instance)

#endregion
