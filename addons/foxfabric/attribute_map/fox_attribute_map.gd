@icon("uid://b5tv46lqk2755")
class_name FoxAttributeMap
extends FoxNode
## A recursive, hierarchical Blackboard node for safely managing dynamic entity data, stacked flags, and rules.
##
## Acts as a centralized data hub for an entity. It can store any arbitrary [Variant] data (such as [int], [String], or [FoxStatPool] resources),
## tracks temporary binary states via stacked string flags, and safely propagates [FoxAttributeRule]s up and down a node hierarchy.
## [codeblock]
## var stats := $AttributeMap as FoxAttributeMap
##
## # Store anything, then group keys for bulk queries.
## stats.set_data(&"health", FoxStatPool.new())
## stats.set_data(&"move_speed", 5.0)
## stats.add_data_to_group(&"move_speed", &"movement")
##
## # Flags are stacked, not boolean. Two sources of slow both have to expire.
## stats.increment_flag(&"slowed")   # a swamp
## stats.increment_flag(&"slowed")   # and a debuff
## stats.decrement_flag(&"slowed")   # leaving the swamp
## stats.has_flag(&"slowed")         # still true, the debuff holds the last stack
## [/codeblock]




#region Signals

## Emitted when a new [param key] is added to the data with the given [param value].
signal data_added(key: StringName, value: Variant)
## Emitted when the [param value] of an existing [param key] is overwritten.
signal data_replaced(key: StringName, value: Variant)
## Emitted when a data [param key] is completely removed from the map.
signal data_removed(key: StringName, value: Variant)

## Emitted when a data [param key] is categorized into a [param group].
signal data_added_to_group(group: StringName, key: StringName)
## Emitted when a data [param key] is removed from a [param group].
signal data_removed_from_group(group: StringName, key: StringName)

## Emitted when an active [param rule] is applied to this map.
signal rule_added(rule: FoxAttributeRule)
## Emitted when an active [param rule] expires or is removed.
signal rule_removed(rule: FoxAttributeRule)

## Emitted the first time a [param flag]'s stack reaches [code]1[/code].
signal flag_added(flag: StringName)
## Emitted when a [param flag]'s stack reaches [code]0[/code] and is completely removed.
signal flag_removed(flag: StringName)
## Emitted any time a [param flag]'s stack count increases or decreases.
signal flag_changed(flag: StringName, stacks: int)

#endregion




#region Variables

## If [code]true[/code], this map will accept and apply rules propagated from a parent map.
@export var can_receive_rules: bool = true
## If [code]true[/code], this map will propagate its active rules down to any registered child maps.
@export var can_send_rules: bool = true

var _data: Dictionary[StringName, Variant] = {}
var _groups: Dictionary[StringName, Array] = {}
var _active_rules: Array[FoxAttributeRule] = []
var _flags: Dictionary[StringName, int] = {}
var _parent_map: FoxAttributeMap
var _child_maps: Array[FoxAttributeMap] = []

#endregion




#region Data

## Adds or updates a piece of data in the internal dictionary. Emits [signal data_added] if the 
## [param key] is new, or [signal data_replaced] if the [param key] already exists.
func set_data(key: StringName, value: Variant) -> void:
	var is_new = not _data.has(key)
	
	_data[key] = value
	
	if is_new:
		data_added.emit(key, value)
	else:
		data_replaced.emit(key, value)


## Retrieves data associated with the given [param key]. Returns [param default_value] if the 
## [param key] does not exist.
func get_data(key: StringName, default_value: Variant = null) -> Variant:
	return _data.get(key, default_value)


## Returns [code]true[/code] if the exact key exists in the data dictionary.
func has_data(key: StringName) -> bool:
	return _data.has(key)


## Completely removes data associated with the given [param key] and purges it from any 
## associated groups. Emits [signal data_removed].
func erase_data(key: StringName) -> void:
	if not _data.has(key):
		return
		
	var removed_value = _data[key]
	_data.erase(key)
	
	erase_data_from_all_groups(key)
			
	data_removed.emit(key, removed_value)

#endregion




#region Groups

## Associates an existing data [param key] with a specific [param group] string for bulk querying.
func add_data_to_group(key: StringName, group: StringName) -> void:
	# prevent ghost data
	if not _data.has(key):
		push_warning("FoxAttributeMap: Cannot group missing data '%s'." % key)
		return
	
	# create group if it doesn't exist
	if not _groups.has(group):
		create_group(group)
	
	# prevent duplicate entries
	if _groups[group].has(key):
		return
		
	_groups[group].append(key)
	data_added_to_group.emit(group, key)


## Removes a specific data key from a group.
func erase_data_from_group(key: StringName, group: StringName) -> void:
	# does the group and key exist
	if not _groups.has(group) or not _groups[group].has(key):
		return
	
	_groups[group].erase(key)
	data_removed_from_group.emit(group, key)


## Helper function that purges a key from all groups it currently belongs to.
func erase_data_from_all_groups(key: StringName) -> void:
	# uses duplicate() because arrays/dicts shouldn't be modified while iterating
	for group in _groups.keys().duplicate():
		erase_data_from_group(key, group)


## Returns an array of all actual data [Variant]s currently associated with the target [param group].
func get_data_in_group(group: StringName) -> Array[Variant]:
	var results: Array[Variant] = []
	
	if not _groups.has(group):
		return results
		
	for key in _groups[group]:
		if _data.has(key): 
			results.append(_data[key])
			
	return results


## Explicitly creates an empty group tracking array.
func create_group(group: StringName) -> void:
	if not _groups.has(group):
		_groups[group] = []


## Completely destroys a [param group] and disassociates all keys inside of it. 
## Returns [code]true[/code] if the [param group] existed and was erased, or [code]false[/code] if it did not exist.
func erase_group(group: StringName) -> bool:
	if not _groups.has(group):
		return false
	
	# helps emit data_removed
	var members = _groups[group].duplicate()
	for key in members:
		erase_data_from_group(key, group)
	
	return _groups.erase(group)


## Returns [code]true[/code] if the group exists.
func has_group(group: StringName) -> bool:
	return _groups.has(group)

#endregion




#region Flags

## Adds one stack to a string-based [param flag]. If this is the first stack applied, 
## emits [signal flag_added]. Always emits [signal flag_changed].
func increment_flag(flag: StringName) -> void:
	if not _flags.has(flag):
		_flags[flag] = 0
		
	_flags[flag] += 1
	
	# only emit the flag_added signal on the very first stack
	if _flags[flag] == 1:
		flag_added.emit(flag)
	
	flag_changed.emit(flag, _flags[flag])


## Removes one stack from a string-based [param flag]. If the stack count reaches [code]0[/code], 
## the flag is erased entirely and emits [signal flag_removed].
func decrement_flag(flag: StringName) -> void:
	if not _flags.has(flag):
		return
		
	_flags[flag] -= 1
	
	# is the flag's stack 0
	if _flags[flag] <= 0:
		_flags.erase(flag)
		flag_changed.emit(flag, 0) 
		flag_removed.emit(flag)
	else:
		flag_changed.emit(flag, _flags[flag])


## Returns [code]true[/code] if the [param flag] exists with at least one stack.
func has_flag(flag: StringName) -> bool:
	return _flags.has(flag)


## Returns the exact number of times this flag has been stacked.
func get_flag_stacks(flag: StringName) -> int:
	return _flags.get(flag, 0)


## Forcefully removes all stacks of a flag instantly.
func erase_flag(flag: StringName) -> void:
	if not _flags.has(flag):
		return
		
	_flags.erase(flag)
	flag_changed.emit(flag, 0)
	flag_removed.emit(flag)


## Forcefully purges all active flags on the entity.
func clear_all_flags() -> void:
	# uses duplicate() because arrays/dicts shouldn't be modified while iterating
	for flag in _flags.keys().duplicate():
		erase_flag(flag)

#endregion




#region Rules

## Applies a data-modifying [FoxAttributeRule] to the internal data and propagates it to 
## children if [member can_send_rules] is [code]true[/code].
func add_rule(rule: FoxAttributeRule) -> void:
	_apply_rule(rule, false)


func _apply_rule(rule: FoxAttributeRule, from_parent: bool) -> void:
	# can_receive_rules only gates inheritance, never a direct local call
	if from_parent and not can_receive_rules:
		return

	# prevent duplicate rules in memory
	if _active_rules.has(rule):
		return

	_active_rules.append(rule)
	rule_added.emit(rule)

	# Apply rule to the map itself!
	if _data.has(rule.target_key):
		rule.apply_to(self)

	if can_send_rules:
		for child in _child_maps:
			child._apply_rule(rule, true)


## Removes a [FoxAttributeRule] by matching its [member FoxAttributeRule.id]. 
## Reverses the rule's mathematical effects on the local data and emits [signal rule_removed].
func remove_rule(id: StringName) -> void:
	# find rule in data with id
	var rule_to_remove: FoxAttributeRule = null
	for rule in _active_rules:
		if rule.id == id:
			rule_to_remove = rule
			break
	
	if not rule_to_remove:
		return 
		
	_active_rules.erase(rule_to_remove)
	rule_removed.emit(rule_to_remove)
	
	# Remove rule from the map itself!
	if _data.has(rule_to_remove.target_key):
		rule_to_remove.remove_from(self)
	
	if can_send_rules:
		for child in _child_maps:
			child.remove_rule(id)


## Returns the array of currently active and applied [FoxAttributeRule]s.
func get_active_rules() -> Array[FoxAttributeRule]:
	return _active_rules

#endregion




#region Hierarchy

func _enter_tree() -> void:
	_parent_map = _find_parent_map(get_parent())
	
	if _parent_map:
		_parent_map.register_child_map(self)


func _find_parent_map(node: Node) -> FoxAttributeMap:
	# top of scene tree
	if not node:
		return null
	
	# node is the parent node
	if node is FoxAttributeMap:
		return node
	
	# check node for a child FoxAttributeMap
	for child in node.get_children():
		if child is FoxAttributeMap and child != self:
			return child
	
	# run again on the parent of node
	return _find_parent_map(node.get_parent())


func _exit_tree() -> void:
	# clean up this FoxAttributeMap
	if is_instance_valid(_parent_map):
		_parent_map.unregister_child_map(self)


## Links a child map to this parent, passing down all current rules and flags.
func register_child_map(child: FoxAttributeMap) -> void:
	# check for duplicates
	if _child_maps.has(child):
		return
	
	_child_maps.append(child)
	
	if not can_send_rules:
		return
	
	# late-joiner propagation
	for rule in _active_rules:
		child._apply_rule(rule, true)
		
	for flag in _flags:
		for i in range(_flags[flag]):
			child.increment_flag(flag)


## Unlinks a child map and strips away any rules and flags it inherited from this parent.
func unregister_child_map(child: FoxAttributeMap) -> void:
	_child_maps.erase(child)
	
	# remove the _parent_map's rules from the departing child
	for rule in _active_rules:
		child.remove_rule(rule.id)
		
	# remove the _parent_map's visual states from the departing child
	for flag in _flags:
		for i in range(_flags[flag]):
			child.decrement_flag(flag)

#endregion
