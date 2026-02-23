extends FoxResource
class_name FoxModifiableStat
## Changes a number based on two lists of modifiers.
##
## FinalValue = (Base + ∑Flat) * ∑Multipliers
## The flat_modifiers do addition (+) operations on the base value.
## The multiplier_modifiers do multiplication (*) operations on the base value afterwards. 
## Flat bonuses are applied first, then the total of all multiplier_modifiers are tallied up and applied.
## For an example with speed, a base_value of 5.0 with 
## flat_modifiers{"potion_1" : 2.0, "injured" : -1.0} causes: 5.0 [base] + 2.0 [potion_1] + (-1) [injured] = 6.0.
## With the multiplier_modifiers{"speed_boots" : 1.6, "slowed" : -0.7} the final multiplier is:
## 1.0 [base] + 0.6 [speed_boots] + (-0.7) [slowed] = 0.9. This is now applied to our amount from before:
## 6.0 * 0.9 = 5.4



## oh my god this was so absolutely bloody annoying to figure out
## in a clean way that was well documented i could literally make
## an entire video on this stupid script


#region Signals

## Emitted when value changes
signal value_changed(new_value: float)
## Emitted when clear_all_modifiers() is called.
signal all_modifiers_cleared(new_value: float)

## Emitted when a new modifier is added.
signal modifier_added(modifier_id: StringName, is_multiplier: bool, instance_value : float)
## Emitted when a modifier is removed.
signal modifier_removed(modifier_id: StringName, instance_value : float)

## Emitted when a new multiplier_modifier is removed.
signal multiplier_modifier_removed(modifier_id: StringName, is_multiplier: bool, instance_value : float)
## Emitted when an multiplier_modifier is added.
signal multiplier_modifier_added(modifier_id: StringName, instance_value : float)

## Emitted when a new flat_modifier is added.
signal flat_modifier_added(modifier_id: StringName, instance_value : float)
## Emitted when a flat_modifier is removed.
signal flat_modifier_removed(modifier_id: StringName, instance_value : float)

#endregion


#region Variables

## The original stat that gets modified.
@export var base_value: float = 0.0:
	set(v):
		base_value = v
		_recalculate()

## Dictionary of all flat_modifier instances on this ModifiableStat. 
## Flat modifier instances can be negative to make them penalties.
## The StringName key is the id of the flat_modifier, the Array represents each flat_modifier instance with that matching id. 
## Every index in this Array points to what the value of that instance is. 
## This allows multiple copies of the same id that can have their own value.
## Two +2 "extra_health" bonuses totaling to +4: multipliers{"extra_health", [2, 2]}
## A +1 "extra_health" and a +2 "extra_health" totaling to 3: multipliers{"speed_boost", [0.30, 0.60]}
var flat_modifiers: Dictionary[StringName, Array] = {}
## Dictionary  of all multiplier instances on this ModifiableStat. 
## Multiplier instances can be negative to make them penalties.
## The StringName key is the id of the multiplier, the Array represents each multiplier instance with that matching id. 
## Every index in this Array points to what the value of that instance is. 
## This allows multiple copies of the same id that can have their own value.
## Two 60% "speed_boost" bonuses totaling to 120%: multipliers{"speed_boost", [0.60, 0.60]}
## A 30% "speed_boost" and a 60% "speed_boost" totaling to 90%: multipliers{"speed_boost", [0.30, 0.60]}
var multiplier_modifiers: Dictionary[StringName, Array] = {}

## The 'cached' value for internal use. Do not use.
var _current_value: float = 0.0

## The final value after applying all the  Public read-only access
var value: float:
	get: return _current_value
	set(_v): assert(false, "ERROR: ModifiableStat: 'value' is read-only. Please change the base_value, flat_modifiers{} or multipliers{}")

#endregion


#region Modifiers

## Adds a modifier instance.
func add_modifier(id: StringName, is_multiplier: bool, instance_value: float) -> void:
	var target_dict := _get_target_dict(is_multiplier)

	if not target_dict.has(id):
		target_dict[id] = [] # Initialize the array if it doesn't exist

	target_dict[id].append(instance_value)
	_recalculate()
	modifier_added.emit(id, is_multiplier, instance_value)


## Removes instances of a modifier.
## Returns a float from the value of the instance that was removed. 
## Returns an array of floats if multiple instances were removed.
## Returns NAN if no value was removed. 
## ID specifies what modifier to remove.
## is_multiplier specifies whether to look in the flat_modifiers or the multipliers dictionaries.
## all_instances deletes every instance with that matching ID. Not specifying all_copies deletes only the most recent instance.
## specific_value will find the first instance of a matching ID that has a specific value and remove it.
## Pair all_instances and specific_value to remove all instances of a matching ID that have a specific value.  
func remove_modifier(id: StringName, is_multiplier: bool, all_instances: bool = false, specific_value : = NAN):
	var target_dict := _get_target_dict(is_multiplier)
	var return_value
	
	# No matching id could be found 
	if not has_modifier(id, is_multiplier): 
		return NAN
	
	# Most basic
	# Remove the most recent instance matching ID
	if all_instances == false and is_nan(specific_value):
		
		var last_index : int = target_dict[id].size() -1
		var instance_value : float = target_dict[id][last_index]
		
		target_dict[id].pop_back()
		
		modifier_removed.emit(id, instance_value)
		
		return_value = instance_value
	
	# Remove all instances of an ID in a target_dict
	if all_instances == true and is_nan(specific_value):
		var array_of_values := target_dict[id].duplicate()
		
		target_dict[id].clear()
		
		if array_of_values.size() == 1:
			return_value = array_of_values[0]
		else:
			return_value = array_of_values
	
	
	# Remove the most recent instance that has a specific value
	if all_instances == false and not is_nan(specific_value):
		# For example with multipliers{"speed_boost" : [5.0, 3.0, 3.0]}
		# Specifying all_instances = false and specific_value = 3.0
		# removes index 2 creating:
		# multipliers{"speed_boost" : [5.0, 3.0]}
		if target_dict[id].has(specific_value):
			target_dict[id].erase(specific_value)
			return_value = specific_value
		else:
			return_value = NAN
	
	# Remove all instances that have a specific value
	if all_instances == true and not is_nan(specific_value):
		# For example with multipliers{"speed_boost" : [5.0, 3.0, 3.0]}
		# Specifying all_instances = true and specific_value = 3.0
		# removes index 1 and 2 creating:
		# multipliers{"speed_boost : [5.0]}
		return_value = _erase_all_instances_of_specific_value(id, specific_value, target_dict)
		
	_recalculate()
	_cleanup_empty_modifiers(id, target_dict)
	
	return return_value

#endregion


#region Public Helpers

## Returns true if an instance matching an ID could be found. 
func has_modifier(id: StringName, is_multiplier: bool) -> bool:
	var target_dict = _get_target_dict(is_multiplier)
	if target_dict.has(id): 
		return true
	else:
		return false


## Clears all modifiers.
func clear_all_modifiers() -> void:
	multiplier_modifiers.clear()
	flat_modifiers.clear()
	_recalculate()
	all_modifiers_cleared.emit()

#endregion


#region Flat Modifiers

## Adds a flat modifier instance.
func add_flat_modifier(id: StringName, instance_value: float) -> void:
	add_modifier(id, false, instance_value)
	flat_modifier_added.emit(id, instance_value)


## Removes instances of a flat_modifier.
## Returns a float from the value of the instance that was removed. 
## Returns an array of floats if multiple instances were removed.
## Returns NAN if no value was removed. 
## ID specifies what modifier to remove.
## all_instances deletes every instance with that matching ID. Not specifying all_copies deletes only the most recent instance.
## specific_value will find the first instance of a matching ID that has a specific value and remove it.
## Pair all_instances and specific_value to remove all instances of a matching ID that have a specific value.  
func remove_flat_modifier(id: StringName, all_instances: bool = false, specific_amount: float = NAN):
	var value_of_removed_modifier = remove_modifier(id, false, all_instances, specific_amount)
	flat_modifier_removed.emit(id, value_of_removed_modifier)
	
	if value_of_removed_modifier == null:
		return NAN
	
	return value_of_removed_modifier

#endregion


#region Multiplier Modifiers

## Adds a multiplier modifier instance.
func add_multiplier_modifier(id: StringName, instance_value: float) -> void:
	add_modifier(id, true, instance_value)
	multiplier_modifier_added.emit(id, instance_value)


## Removes instances of a multiplier.
## Returns a float from the value of the instance that was removed. 
## Returns an array of floats if multiple instances were removed.
## Returns NAN if no value was removed. 
## ID specifies what modifier to remove.
## all_instances deletes every instance with that matching ID. Not specifying all_copies deletes only the most recent instance.
## specific_value will find the first instance of a matching ID that has a specific value and remove it.
## Pair all_instances and specific_value to remove all instances of a matching ID that have a specific value.  
func remove_multiplier_modifier(id: StringName, all_instances: bool = false, specific_amount: float = NAN):
	var value_of_removed_modifier = remove_modifier(id, true, all_instances, specific_amount)
	multiplier_modifier_removed.emit(id, value_of_removed_modifier)
	
	if value_of_removed_modifier == null:
		return NAN
	
	return value_of_removed_modifier


#endregion


#region Private

func _init(p_base: float = 1.0):
	base_value = p_base
	_recalculate()


func _cleanup_empty_modifiers(id : StringName, target_dict : Dictionary[StringName, Array]):
	# Don't empty IDs with no instances
	if target_dict[id].is_empty():
		target_dict.erase(id)


func _recalculate() -> void:
	var total_flat := 0.0
	for list in flat_modifiers.values():
		for v in list:
			total_flat += v
			
	var total_mult := 1.0
	for list in multiplier_modifiers.values():
		for v in list:
			total_mult += v
	
	_current_value = (base_value + total_flat) * total_mult
	value_changed.emit(_current_value)


func _get_target_dict(is_multiplier : bool) -> Dictionary[StringName, Array]:
	return multiplier_modifiers if is_multiplier else flat_modifiers


func _erase_all_instances_of_specific_value(id : StringName, specific_value: float, target_dict : Dictionary[StringName, Array]):
	# This took some figuring out because of all the nesting...
	# Target_dict is a Dictionary[StringName, Array]
	# Inside each array is an array of floats
	# It looks something like this:
	# multipliers{"speed_boost" : [5.0, 3.0, 3.0]}

	# id = "speed_boost"
	# specific_value = 5.0 or 3.0
	var values_to_erase : = []
	var new_array : = []

	for _value in target_dict[id]:
		if _value == specific_value:
			values_to_erase.append(_value)
		else:
			new_array.append(_value)
	
	target_dict[id] = new_array
	
	if values_to_erase.size() == 0:
		return NAN
	elif values_to_erase.size() == 1:
		return values_to_erase[0]
	else:
		return values_to_erase
		
	#target_dict[id].erase(specific_value)
	
#endregion
