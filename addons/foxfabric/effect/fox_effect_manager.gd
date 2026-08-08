@icon("uid://dsv5at5ud3kja")
class_name FoxEffectManager
extends FoxNode
## Handles the creation, lifecycle, and cleanup of [FoxEffectInstance] objects.


#region Signals

## Emitted immediately after a new [FoxEffectInstance] is instantiated and added.
signal effect_added(instance: FoxEffectInstance)

## Emitted immediately after a [FoxEffectInstance] is cleaned up and removed.
signal effect_removed(instance: FoxEffectInstance)

#endregion


#region Variables

## The internal list of currently active effect instances.
var effects: Array[FoxEffectInstance] = []

#endregion


#region Built-In Virtuals

func _ready() -> void:
	# nothing to tick until an effect is added
	set_process(false)


func _process(delta: float) -> void:
	for i in range(effects.size() - 1, -1, -1):
		var instance = effects[i]
		
		instance.process_time(delta)
		
		if instance.is_expired:
			_remove_instance_at(i)

#endregion


#region Public API

## Applies a [FoxEffect] to the [param target]. 
## [br][br]
## Depending on the effect's [member FoxEffect.stack_mode], this will either 
## return an updated existing instance or instantiate a brand new one.
func add_effect(effect: FoxEffect, target: Object) -> FoxEffectInstance:
	if not effect: 
		return null

	var existing_instance = _get_instance_by_id(effect.id)
	var use_multiple_instances : bool = effect.stack_mode == FoxEffect.StackMode.MULTIPLE_INSTANCES
	
	if not existing_instance or use_multiple_instances:
		return _create_new_instance(effect, target)

	existing_instance.merge_duration(effect)
	
	if effect.stack_mode == FoxEffect.StackMode.INTENSITY:
		existing_instance.increase_stack(1)
		
	return existing_instance




## Removes a specific instance object from tracking and executes its cleanup logic.
func remove_instance(instance: FoxEffectInstance) -> void:
	var idx = effects.find(instance)
	if idx != -1:
		_remove_instance_at(idx)


## Removes active instances matching the specified [param target_id].
## [br][br]
## If [param all_instances] is [code]false[/code], it will only remove the first one found.
func remove_effect_by_id(target_id: StringName, all_instances: bool = false) -> void:
	for i in range(effects.size() - 1, -1, -1):
		if effects[i].effect.id == target_id:
			_remove_instance_at(i)
			if not all_instances:
				return


## Purges every active effect currently managed and runs their cleanup logic.
func remove_all_effects() -> void:
	for i in range(effects.size() - 1, -1, -1):
		_remove_instance_at(i)


## Returns an array of every unique [member FoxEffect.id] currently active on the target.
func get_all_effect_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for instance in effects:
		ids.append(instance.effect.id)
	return ids


## A quick helper to check if a specific effect is currently active.
func has_effect(target_id: StringName) -> bool:
	return _get_instance_by_id(target_id) != null

#endregion


#region Serialization

## Returns an array of dictionaries representing the active state of all managed effects.
func serialize() -> Array[Dictionary]:
	var save_data: Array[Dictionary] = []
	for instance in effects:
		save_data.append(instance.serialize())
	return save_data


## Rebuilds the active effects from saved data.
## Requires the [param target] and a [Callable] that takes a [StringName] ID and returns a [FoxEffect].
func load_state(save_data: Array, target: Object, blueprint_lookup: Callable) -> void:
	remove_all_effects()
	
	for data in save_data:
		var effect_id: StringName = data.get("id", &"")
		var blueprint: FoxEffect = blueprint_lookup.call(effect_id)
		
		if not blueprint:
			push_warning("FoxEffectManager: Could not load blueprint for ID '%s'" % effect_id)
			continue
			
		var instance := FoxEffectInstance.new()
		
		instance.setup(blueprint, target)
		instance.load_state(data)
		instance.request_destruction.connect(_on_instance_request_destruction)
		
		effects.append(instance)
		
		# Note: We purposely bypass effect.execute() here so we don't 
		# trigger initial burst damage or sounds when loading a save file.

	set_process(not effects.is_empty())

#endregion


#region Private

func _get_instance_by_id(target_id: StringName) -> FoxEffectInstance:
	for instance in effects:
		if instance.effect.id == target_id:
			return instance
	return null


func _remove_instance_at(index: int) -> void:
	var instance = effects[index]
	
	instance.request_destruction.disconnect(_on_instance_request_destruction)
	instance.cleanup()
	
	effects.remove_at(index)
	set_process(not effects.is_empty())

	effect_removed.emit(instance)


func _on_instance_request_destruction(instance: FoxEffectInstance) -> void:
	remove_instance(instance)


func _create_new_instance(effect: FoxEffect, target: Object) -> FoxEffectInstance:
	var new_instance := FoxEffectInstance.new()
	
	new_instance.setup(effect, target)
	new_instance.request_destruction.connect(_on_instance_request_destruction)
	
	effect.execute(target)
	
	effects.append(new_instance)
	set_process(true)
	effect_added.emit(new_instance)
	
	return new_instance

#endregion
