@icon("uid://cc75ukbud54ws")
extends FoxResource
class_name FoxModifiableStat
## A resource that calculates a final [float] value based on flat and multiplier modifiers.
##
## Flat modifiers are added to [member base_value] first. That total is then multiplied by
## [code]1.0[/code] plus the sum of all multiplier modifiers, so a single [code]0.5[/code]
## multiplier scales the result by [code]1.5[/code] rather than halving it.
## [codeblock]
## var attack: FoxModifiableStat = FoxModifiableStat.new(100.0)
##
## attack.add_flat_modifier(&"gear", 50.0)
## attack.add_multiplier_modifier(&"rage", 0.5)
## attack.value                                  # (100 + 50) * 1.5 = 225
##
## attack.pop_modifier(&"gear", ModifierType.FLAT)
## attack.value                                  # 100 * 1.5 = 150
## [/codeblock]
## Modifiers are stacked per id, so the same source can apply more than once and be removed one
## layer at a time. [method pop_modifier] takes the most recent off the stack,
## [method clear_modifier] removes every layer under that id at once.
## [codeblock]
## attack.add_flat_modifier(&"poison", -5.0)
## attack.add_flat_modifier(&"poison", -5.0)     # two stacks of the same debuff
## attack.pop_modifier(&"poison", ModifierType.FLAT)   # one wears off
## attack.clear_modifier(&"poison", ModifierType.FLAT) # cured, all layers gone
## [/codeblock]




## Defines how a modifier affects the base value.
enum ModifierType {
	## Added to [member base_value] before any multiplier is applied.
	FLAT,
	## Added to a running total that starts at [code]1.0[/code], which then scales the result.
	## A value of [code]0.5[/code] therefore means "+50%", not "half".
	MULTIPLIER
}




#region Signals

## Emitted when the calculated [member value] changes.
signal value_changed(new_value: float)

## Emitted when a modifier is added via [method add_modifier].
signal modifier_added(id: StringName, type: ModifierType, amount: float)

## Emitted when a modifier is removed via [method pop_modifier], [method clear_modifier], or [method remove_specific_modifier].
signal modifier_removed(id: StringName, type: ModifierType, amount: float)

## Emitted when [method clear_all_modifiers] is called.
signal all_modifiers_cleared()

#endregion




#region Variables

## The base, unmodified value.
@export var base_value: float = 0.0:
	set(v):
		base_value = v
		_recalculate()

# Internal dictionaries. Structure: { StringName : Array[float] }
var _flat_modifiers: Dictionary = {}
var _multiplier_modifiers: Dictionary = {}

var _current_value: float = 0.0

## The final, calculated value. This property is read-only.
var value: float:
	get: return _current_value
	set(_v): push_error("ERROR: FoxModifiableStat 'value' is read-only. Modify the base_value or add/remove modifiers instead.")

#endregion




#region Public API

## Adds a modifier of [param type] with the specified [param amount] to the stack identified by [param id].
func add_modifier(id: StringName, type: ModifierType, amount: float) -> void:
	assert(is_finite(amount), "FoxModifiableStat: Attempted to add a non-finite modifier amount (NaN or INF).")

	var dict = _get_dict(type)

	if not dict.has(id):
		dict[id] = [] # Initialize the array stack if it doesn't exist

	dict[id].append(amount)
	_recalculate()
	modifier_added.emit(id, type, amount)


## Removes the most recently added modifier from the [param id] stack.
## Returns [code]true[/code] if successful.
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


## Instantly removes all instances of a modifier identified by [param id] and [param type].
func clear_modifier(id: StringName, type: ModifierType) -> void:
	var dict = _get_dict(type)

	if dict.has(id):
		var removed_amounts = dict[id].duplicate()
		dict.erase(id)
		_recalculate()

		# Emit for each one removed so UI or floating text listeners stay synced
		for amount in removed_amounts:
			modifier_removed.emit(id, type, amount)


## Removes all modifiers and resets [member value] to [member base_value].
func clear_all_modifiers() -> void:
	_flat_modifiers.clear()
	_multiplier_modifiers.clear()
	_recalculate()
	all_modifiers_cleared.emit()


## Returns [code]true[/code] if a stack exists for [param id].
## [br][br]
## Empty stacks are erased on removal, so an existing stack always holds at least one modifier.
func has_modifier(id: StringName, type: ModifierType) -> bool:
	return _get_dict(type).has(id)


## Removes the first instance matching [param specific_amount] from the [param id] stack.
## Returns [code]true[/code] if successful.
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


## Helper to quickly add a flat modifier without typing the enum.
func add_flat_modifier(id: StringName, amount: float) -> void:
	add_modifier(id, ModifierType.FLAT, amount)


## Helper to quickly add a multiplier modifier without typing the enum.
func add_multiplier_modifier(id: StringName, amount: float) -> void:
	add_modifier(id, ModifierType.MULTIPLIER, amount)


## Helper to quickly pop a flat modifier without typing the enum.
func pop_flat_modifier(id: StringName) -> void:
	pop_modifier(id, ModifierType.FLAT)


## Helper to quickly pop a multiplier modifier without typing the enum.
func pop_multiplier_modifier(id: StringName) -> void:
	pop_modifier(id, ModifierType.MULTIPLIER)

#endregion




#region Private

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
