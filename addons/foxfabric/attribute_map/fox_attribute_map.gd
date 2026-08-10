@icon("uid://b5tv46lqk2755")
class_name FoxAttributeMap
extends FoxNode
## A node that holds an entity's data, counted flags and rules, and propagates them to child maps.
##
## [FoxAttributeMap] stores an entity's values under [StringName] keys, holding anything a [Variant] can
## (such as [int], [String], or [FoxStatPool] resources), tracks temporary states with counted flags, and
## propagates [FoxAttributeRule]s up and down a node hierarchy.
## [codeblock]
## var stats: FoxAttributeMap = $AttributeMap
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
## @tutorial(Building a status effect system): https://foxfabric-godot.readthedocs.io/en/latest/guide_status_effects.html




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

# Keys to whatever the game stored under them: a number, a resource, a FoxModifiableStat. Nothing
# here reads inside a value, which is why a rule has to be told the key it acts on.
var _data: Dictionary[StringName, Variant] = {}

# Group name to the data keys filed under it. Keys rather than values, so overwriting a value
# leaves its grouping alone.
var _groups: Dictionary[StringName, Array] = {}

# Rules applied here, including any that came down from a parent. Propagation shares the rule
# object, so the same instance appears in every map that took it.
var _active_rules: Array[FoxAttributeRule] = []

# Flag name to the number of stacks standing on it. Two sources of one flag both have to expire
# before it lifts, which is what a bool could not carry.
var _flags: Dictionary[StringName, int] = {}

# Found by walking up the scene tree in _enter_tree, and null at the top of a chain. Nothing in a
# scene file wires this up by hand.
var _parent_map: FoxAttributeMap

# Maps that registered themselves beneath this one. Rules and flags travel down this list, and
# nothing is read back up it.
var _child_maps: Array[FoxAttributeMap] = []

#endregion




#region Data

## Adds or updates a piece of data in the internal dictionary. Emits [signal data_added] if the
## [param key] is new, or [signal data_replaced] if the [param key] already exists.
func set_data(key: StringName, value: Variant) -> void:
	var is_new: bool = not _data.has(key)

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


## Every data key currently stored, in insertion order.
func get_data_keys() -> Array[StringName]:
	var keys: Array[StringName] = []
	for key: StringName in _data:
		keys.append(key)

	return keys


## Completely removes data associated with the given [param key] and purges it from any
## associated groups. Emits [signal data_removed].
func erase_data(key: StringName) -> void:
	if not _data.has(key):
		return

	var removed_value: Variant = _data[key]
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
	for group: StringName in _groups.keys().duplicate():
		erase_data_from_group(key, group)


## Returns an array of every data [Variant] currently associated with the target [param group].
func get_data_in_group(group: StringName) -> Array[Variant]:
	var results: Array[Variant] = []

	if not _groups.has(group):
		return results

	for key: StringName in _groups[group]:
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
	var members: Array = _groups[group].duplicate()
	for key: StringName in members:
		erase_data_from_group(key, group)

	return _groups.erase(group)


## Returns [code]true[/code] if the group exists.
func has_group(group: StringName) -> bool:
	return _groups.has(group)


## Every group name that currently exists, including empty ones.
## [br][br]
## Not [code]get_groups[/code], which [Node] already uses for scene groups.
func get_group_names() -> Array[StringName]:
	var names: Array[StringName] = []
	for group: StringName in _groups:
		names.append(group)

	return names


## The data keys filed under [param group]. Empty when the group does not exist.
## [br][br]
## Use [method get_data_in_group] to get the values instead of the keys.
func get_keys_in_group(group: StringName) -> Array[StringName]:
	var keys: Array[StringName] = []
	if not _groups.has(group):
		return keys

	for key: StringName in _groups[group]:
		keys.append(key)

	return keys

#endregion




#region Flags

## Adds one stack to a string-based [param flag]. If this is the first stack applied,
## emits [signal flag_added]. Always emits [signal flag_changed].
## [br][br]
## Passes the stack down to child maps when [member can_send_rules] is [code]true[/code], the same
## way rules travel.
func increment_flag(flag: StringName) -> void:
	if not _flags.has(flag):
		_flags[flag] = 0

	_flags[flag] += 1

	# only emit the flag_added signal on the very first stack
	if _flags[flag] == 1:
		flag_added.emit(flag)

	flag_changed.emit(flag, _flags[flag])

	if can_send_rules:
		for child: FoxAttributeMap in _child_maps:
			child.increment_flag(flag)


## Removes one stack from a string-based [param flag]. If the stack count reaches [code]0[/code],
## the flag is erased entirely and emits [signal flag_removed].
## [br][br]
## Takes the stack back off child maps when [member can_send_rules] is [code]true[/code].
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

	if can_send_rules:
		for child: FoxAttributeMap in _child_maps:
			child.decrement_flag(flag)


## Returns [code]true[/code] if the [param flag] exists with at least one stack.
func has_flag(flag: StringName) -> bool:
	return _flags.has(flag)


## Returns the exact number of times this flag has been stacked.
func get_flag_stacks(flag: StringName) -> int:
	return _flags.get(flag, 0)


## A copy of every active flag and its stack count. Editing it will not change the map.
func get_flags() -> Dictionary[StringName, int]:
	return _flags.duplicate()


## Forcefully removes all stacks of a flag instantly. Takes the same number of stacks back off
## child maps, so a child keeps any stacks it applied to itself.
func erase_flag(flag: StringName) -> void:
	if not _flags.has(flag):
		return

	var stacks: int = _flags[flag]
	_flags.erase(flag)
	flag_changed.emit(flag, 0)
	flag_removed.emit(flag)

	if can_send_rules:
		for child: FoxAttributeMap in _child_maps:
			for _i: int in stacks:
				child.decrement_flag(flag)


## Forcefully purges all active flags on the entity.
func clear_all_flags() -> void:
	# uses duplicate() because arrays/dicts shouldn't be modified while iterating
	for flag: StringName in _flags.keys().duplicate():
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

	# remove_rule matches on id, so a second rule under an id already in use could never be taken
	# off again on its own. Refuse it instead of applying something that cannot be reversed.
	if _find_rule(rule.id) != null:
		push_warning("FoxAttributeMap: A rule with id '%s' is already active." % rule.id)
		return

	_active_rules.append(rule)
	rule_added.emit(rule)

	# Apply rule to the map itself!
	if _data.has(rule.target_key):
		rule.apply_to(self)

	if can_send_rules:
		for child: FoxAttributeMap in _child_maps:
			child._apply_rule(rule, true)


## Removes a [FoxAttributeRule] by matching its [member FoxAttributeRule.id].
## Reverses the rule's mathematical effects on the local data and emits [signal rule_removed].
func remove_rule(id: StringName) -> void:
	var rule_to_remove: FoxAttributeRule = _find_rule(id)
	if rule_to_remove == null:
		return

	_active_rules.erase(rule_to_remove)
	rule_removed.emit(rule_to_remove)

	# Remove rule from the map itself!
	if _data.has(rule_to_remove.target_key):
		rule_to_remove.remove_from(self)

	if can_send_rules:
		for child: FoxAttributeMap in _child_maps:
			child.remove_rule(id)


## Returns a copy of the currently active [FoxAttributeRule]s. Editing it will not change the map.
func get_active_rules() -> Array[FoxAttributeRule]:
	return _active_rules.duplicate()


func _find_rule(id: StringName) -> FoxAttributeRule:
	for rule: FoxAttributeRule in _active_rules:
		if rule.id == id:
			return rule

	return null

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

	# The first step up is this map's own parent, so the maps under it are this map's siblings. A
	# sibling is a peer to inherit alongside, not one to inherit from. Taking one left two maps
	# naming each other once both had been reparented, and a single increment_flag then recursed
	# between the pair until the stack gave out.
	if node != get_parent():
		# check node for a child FoxAttributeMap
		for child: Node in node.get_children():
			if child is FoxAttributeMap:
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
	for rule: FoxAttributeRule in _active_rules:
		child._apply_rule(rule, true)

	for flag: StringName in _flags:
		for _i: int in _flags[flag]:
			child.increment_flag(flag)


## The map this one inherits from, or [code]null[/code] when it is the top of its chain.
func get_parent_map() -> FoxAttributeMap:
	return _parent_map


## A copy of the maps registered beneath this one. Editing it will not change the map.
func get_child_maps() -> Array[FoxAttributeMap]:
	return _child_maps.duplicate()


## Unlinks a child map and strips away any rules and flags it inherited from this parent.
func unregister_child_map(child: FoxAttributeMap) -> void:
	_child_maps.erase(child)

	# remove the _parent_map's rules from the departing child
	for rule: FoxAttributeRule in _active_rules:
		child.remove_rule(rule.id)

	# remove the _parent_map's visual states from the departing child
	for flag: StringName in _flags:
		for _i: int in _flags[flag]:
			child.decrement_flag(flag)

#endregion




#region Inspector

## Publishes the runtime state as read-only inspector properties. The names are written out rather
## than kept in constants, because a constant on this class shows up as a row of its own every time
## anyone inspects a map, and six rows spelling out their own names are not worth reading.
## [br][br]
## A map holds nothing until the game runs, so these are empty while editing. They exist for the
## remote inspector: play the scene, pick the node out of the remote tree, and the data, flags,
## rules and tree position update as they change. Nothing here is stored in the scene file.
func _get_property_list() -> Array[Dictionary]:
	return [
		{
			"name": "Runtime",
			"type": TYPE_NIL,
			"usage": PROPERTY_USAGE_GROUP,
			"hint_string": "runtime_",
		},
		_read_only(&"runtime_data", TYPE_DICTIONARY),
		_read_only(&"runtime_groups", TYPE_DICTIONARY),
		_read_only(&"runtime_flags", TYPE_DICTIONARY),
		_read_only(&"runtime_rules", TYPE_DICTIONARY),
		_read_only(&"runtime_inherited_rules", TYPE_ARRAY),
		_read_only(&"runtime_hierarchy", TYPE_DICTIONARY),
	]


## No PROPERTY_USAGE_STORAGE, so none of this is written into a .tscn.
func _read_only(name: StringName, type: int) -> Dictionary:
	return {
		"name": name,
		"type": type,
		"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_READ_ONLY,
	}


func _get(property: StringName) -> Variant:
	match property:
		&"runtime_data":
			return get_data_summary()
		&"runtime_groups":
			return _groups
		&"runtime_flags":
			return _flags
		&"runtime_rules":
			return get_rule_summary()
		&"runtime_inherited_rules":
			return get_inherited_rule_ids()
		&"runtime_hierarchy":
			return get_hierarchy_summary()

	# null means this object does not handle the property, so the engine keeps looking.
	return null


## Every data key with its value as text. A value is turned into text here, inside the running
## game, because an object reaches the remote inspector as an encoded id and there is nothing
## readable left on it by then. Types carrying a [method Object._to_string] print their contents.
func get_data_summary() -> Dictionary[StringName, String]:
	var summary: Dictionary[StringName, String] = {}
	for key: StringName in _data:
		summary[key] = str(_data[key])

	return summary


## Every active rule as [code]id -> target_key[/code]. Ids are unique per map, so nothing is lost
## by flattening them, and a [FoxAttributeRule] is a [RefCounted] that would reach the remote
## inspector as an unreadable object reference.
func get_rule_summary() -> Dictionary[StringName, StringName]:
	var summary: Dictionary[StringName, StringName] = {}
	for rule: FoxAttributeRule in _active_rules:
		summary[rule.id] = rule.target_key

	return summary


## The ids of active rules that arrived from a map above this one instead of being added here.
## [br][br]
## A rule travels by reference, so the same [FoxAttributeRule] sits in every map that received it.
## Matching on the object rather than on [member FoxAttributeRule.id] keeps a rule added here apart
## from an inherited one even when the two share an id, and leaves nothing to unwind when a rule is
## removed.
func get_inherited_rule_ids() -> Array[StringName]:
	var ids: Array[StringName] = []
	for rule: FoxAttributeRule in _active_rules:
		if _came_from_above(rule):
			ids.append(rule.id)

	return ids


# _find_parent_map can pair two sibling maps as each other's parent, so a walk upwards is not
# guaranteed to end on its own. Every loop here stops on a map it has already passed.
func _came_from_above(rule: FoxAttributeRule) -> bool:
	var seen: Array[FoxAttributeMap] = []
	var walker: FoxAttributeMap = _parent_map

	while is_instance_valid(walker) and walker != self and not seen.has(walker):
		if walker._active_rules.has(rule):
			return true

		seen.append(walker)
		walker = walker._parent_map

	return false


## This map's place in its tree, as [code]node path -> depth[/code]. Depth is counted from this map:
## [code]-1[/code] is the map above it, [code]1[/code] a map below it, and [code]0[/code] this one.
## Maps above come first, in order from the topmost, then this map, then everything beneath it.
## [br][br]
## Walked here instead of in the inspector because a parent map reaches the remote inspector as an
## id that cannot be followed. A map outside the tree has no path and returns nothing.
func get_hierarchy_summary() -> Dictionary[String, int]:
	var summary: Dictionary[String, int] = {}
	if not is_inside_tree():
		return summary

	var above: Array[FoxAttributeMap] = []
	var walker: FoxAttributeMap = _parent_map

	while is_instance_valid(walker) and walker != self and not above.has(walker):
		above.push_front(walker)
		walker = walker._parent_map

	var depth: int = -above.size()
	for map: FoxAttributeMap in above:
		if map.is_inside_tree():
			summary[String(map.get_path())] = depth

		depth += 1

	summary[String(get_path())] = 0
	_collect_maps_below(summary, 1)

	return summary


# Depth first, so a child's own children follow it and the read-out can indent straight down the
# dictionary. A path already present marks a loop and ends that branch.
func _collect_maps_below(summary: Dictionary[String, int], depth: int) -> void:
	for child: FoxAttributeMap in _child_maps:
		if not is_instance_valid(child) or not child.is_inside_tree():
			continue

		var path: String = String(child.get_path())
		if summary.has(path):
			continue

		summary[path] = depth
		child._collect_maps_below(summary, depth + 1)

#endregion
