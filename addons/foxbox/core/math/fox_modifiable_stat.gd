extends FoxResource
class_name FoxModifiableStat
## A resource that calculates a final value based on flat and multiplier modifiers.
## Flat modifiers are added to the base value first, then the total is multiplied
## by the sum of all multiplier modifiers.

enum ModifierType {
	FLAT,
	MULTIPLIER
}





#region Signals

## Emitted whenever the final calculated value changes.
signal value_changed(new_value: float)

## Emitted when a new modifier is added.
signal modifier_added(id: StringName, type: ModifierType, amount: float)

## Emitted when a modifier is removed.
signal modifier_removed(id: StringName, type: ModifierType, amount: float)

## Emitted when clear_all_modifiers() is called.
signal all_modifiers_cleared()

#endregion





#region Variables

## The raw, unmodified starting stat.
@export var base_value: float = 0.0:
	set(v):
		base_value = v
		_recalculate()

# Internal dictionaries. Structure: { StringName : Array[float] }
var _flat_modifiers: Dictionary = {}
var _multiplier_modifiers: Dictionary = {}

var _current_value: float = 0.0

## The final, calculated value. Read-only.
var value: float:
	get: return _current_value
	set(_v): push_error("ERROR: FoxModifiableStat 'value' is read-only. Modify the base_value or add/remove modifiers instead.")

#endregion





#region Public API

## Adds a modifier instance to the stat.
func add_modifier(id: StringName, type: ModifierType, amount: float) -> void:
	var dict = _get_dict(type)
	
	if not dict.has(id):
		dict[id] = [] # Initialize the array stack if it doesn't exist
		
	dict[id].append(amount)
	_recalculate()
	modifier_added.emit(id, type, amount)


## Removes the most recently added instance of this modifier ID (pops the stack). 
## Returns true if a modifier was successfully found and removed.
func pop_modifier(id: StringName, type: ModifierType) -> bool:
	var dict = _get_dict(type)
	
	if dict.has(id) and not dict[id].is_empty():
		var removed_amount: float = dict[id].pop_back()
		
		# Cleanup the key entirely if the stack is now empty
		if dict[id].is_empty():
			dict.erase(id)
			
		_recalculate()
		modifier_removed.emit(id, type, removed_amount)
		return true
		
	return false


## Acts as a "Cleanse". Instantly deletes ALL instances of a specific modifier ID.
func clear_modifier(id: StringName, type: ModifierType) -> void:
	var dict = _get_dict(type)
	
	if dict.has(id):
		var removed_amounts = dict[id].duplicate()
		dict.erase(id)
		_recalculate()
		
		# Emit for each one removed so UI or floating text listeners stay synced
		for amount in removed_amounts:
			modifier_removed.emit(id, type, amount)


## Completely wipes all modifiers from the stat, returning it to its base_value.
func clear_all_modifiers() -> void:
	_flat_modifiers.clear()
	_multiplier_modifiers.clear()
	_recalculate()
	all_modifiers_cleared.emit()


## Returns true if at least one instance of the modifier ID is currently active.
func has_modifier(id: StringName, type: ModifierType) -> bool:
	return _get_dict(type).has(id)


## Hunts down the first instance of a specific value within a modifier ID's stack and removes it.
## Returns true if the specific value was found and removed.
func remove_specific_modifier(id: StringName, type: ModifierType, specific_amount: float) -> bool:
	var dict = _get_dict(type)
	
	if dict.has(id):
		var stack: Array = dict[id]
		var index = stack.find(specific_amount)
		
		if index != -1:
			stack.remove_at(index)
			
			# Cleanup the key entirely if the stack is now empty
			if stack.is_empty():
				dict.erase(id)
				
			_recalculate()
			modifier_removed.emit(id, type, specific_amount)
			return true
			
	return false

#endregion





#region Private Logic

func _init(p_base: float = 0.0) -> void:
	base_value = p_base
	_current_value = base_value


func _get_dict(type: ModifierType) -> Dictionary:
	return _multiplier_modifiers if type == ModifierType.MULTIPLIER else _flat_modifiers


func _recalculate() -> void:
	var total_flat := 0.0
	for list in _flat_modifiers.values():
		for v in list:
			total_flat += v
			
	var total_mult := 1.0
	for list in _multiplier_modifiers.values():
		for v in list:
			total_mult += v
			
	var old_value = _current_value
	_current_value = (base_value + total_flat) * total_mult
	
	# Only emit the signal if the math actually changed the final number!
	if _current_value != old_value:
		value_changed.emit(_current_value)

#endregion
