class_name FoxAttributeMap
extends FoxNode

#region Signals

# Data
signal data_added(key: StringName, value: Variant)
signal data_replaced(key: StringName, value: Variant)
signal data_removed(key: StringName, value: Variant)

# Groups
signal data_added_to_group(group: StringName, key: StringName)
signal data_removed_from_group(group: StringName, key: StringName)

# Rules
signal rule_added(rule: FoxAttributeRule)
signal rule_removed(rule: FoxAttributeRule)

# Flags
signal flag_added(flag: StringName)
signal flag_removed(flag: StringName)
signal flag_changed(flag: StringName, stacks: int)

#endregion



#region Variables

@export var can_receive_rules: bool = true
@export var can_send_rules: bool = true

var _data: Dictionary[StringName, Variant] = {}
var _groups: Dictionary[StringName, Array] = {}
var _active_rules: Array[FoxAttributeRule] = []
var _flags: Dictionary[StringName, int] = {}
var _parent_map: FoxAttributeMap
var _child_maps: Array[FoxAttributeMap] = []

#endregion



#region Data

func set_data(key: StringName, value: Variant) -> void:
	var is_new = not _data.has(key)
	
	_data[key] = value
	
	if is_new:
		data_added.emit(key, value)
	else:
		data_replaced.emit(key, value)


func get_data(key: StringName, default_value: Variant = null) -> Variant:
	return _data.get(key, default_value)


func has_data(key: StringName) -> bool:
	return _data.has(key)


func erase_data(key: StringName) -> void:
	if not _data.has(key):
		return
		
	var removed_value = _data[key]
	_data.erase(key)
	
	erase_data_from_all_groups(key)
			
	data_removed.emit(key, removed_value)

#endregion



#region Groups

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


func erase_data_from_group(key: StringName, group: StringName) -> void:
	# does the group and key exist
	if not _groups.has(group) or not _groups[group].has(key):
		return
	
	_groups[group].erase(key)
	data_removed_from_group.emit(group, key)


func erase_data_from_all_groups(key: StringName) -> void:
	# uses duplicate() because arrays/dicts shouldn't be modified while iterating
	for group in _groups.keys().duplicate():
		erase_data_from_group(key, group)


func get_data_in_group(group: StringName) -> Array[Variant]:
	var results: Array[Variant] = []
	
	if not _groups.has(group):
		return results
		
	for key in _groups[group]:
		if _data.has(key): 
			results.append(_data[key])
			
	return results


func create_group(group: StringName) -> void:
	if not _groups.has(group):
		_groups[group] = []


func erase_group(group: StringName) -> bool:
	if not _groups.has(group):
		return false
	
	# helps emit data_removed
	var members = _groups[group].duplicate()
	for key in members:
		erase_data_from_group(key, group)
	
	return _groups.erase(group)


func has_group(group: StringName) -> bool:
	return _groups.has(group)

#endregion



#region Flags

func increment_flag(flag: StringName) -> void:
	if not _flags.has(flag):
		_flags[flag] = 0
		
	_flags[flag] += 1
	
	# only emit the flag_added signal on the very first stack
	if _flags[flag] == 1:
		flag_added.emit(flag)
	
	flag_changed.emit(flag, _flags[flag])


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


func has_flag(flag: StringName) -> bool:
	return _flags.has(flag)


func get_flag_stacks(flag: StringName) -> int:
	return _flags.get(flag, 0)


func erase_flag(flag: StringName) -> void:
	if not _flags.has(flag):
		return
		
	_flags.erase(flag)
	flag_changed.emit(flag, 0)
	flag_removed.emit(flag)


func clear_all_flags() -> void:
	# uses duplicate() because arrays/dicts shouldn't be modified while iterating
	for flag in _flags.keys().duplicate():
		erase_flag(flag)

#endregion



#region Rules

func add_rule(rule: FoxAttributeRule) -> void:
	if not can_receive_rules:
		return
		
	# prevent duplicate rules in memory
	# (if a buff is refreshed, handle overwriting here)
	if _active_rules.has(rule):
		return
		
	_active_rules.append(rule)
	rule_added.emit(rule)
	
	# apply rule to local data
	if _data.has(rule.target_key):
		rule.apply_to(_data[rule.target_key])
	
	if can_send_rules:
		for child in _child_maps:
			child.add_rule(rule)


func remove_rule(rule_id: StringName) -> void:
	# find rule in data with rule_id
	var rule_to_remove: FoxAttributeRule = null
	for rule in _active_rules:
		if rule.rule_id == rule_id:
			rule_to_remove = rule
			break
	
	if not rule_to_remove:
		return 
		
	_active_rules.erase(rule_to_remove)
	rule_removed.emit(rule_to_remove)
	
	# remove rule from local data
	if _data.has(rule_to_remove.target_key):
		rule_to_remove.remove_from(_data[rule_to_remove.target_key])
	
	if can_send_rules:
		for child in _child_maps:
			child.remove_rule(rule_id)


func get_active_rules() -> Array[FoxAttributeRule]:
	return _active_rules

#endregion



#region Networking

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


func register_child_map(child: FoxAttributeMap) -> void:
	# check for duplicates
	if _child_maps.has(child):
		return
	
	_child_maps.append(child)
	
	if not can_send_rules:
		return
	
	# late-joiner
	# this is so that when we make this make, have a bunch of rules/flags,
	# then a new child map is added it gets this maps rules/flags
	for rule in _active_rules:
		child.add_rule(rule)
	for flag in _flags:
		for i in range(_flags[flag]):
			child.add_flag(flag)


func unregister_child_map(child: FoxAttributeMap) -> void:
	_child_maps.erase(child)
	
	# remove the _parent_map's rules from the departing child
	for rule in _active_rules:
		child.remove_rule(rule.rule_id)
		
	# remove the _parent_map's visual states from the departing child
	for flag in _flags:
		for i in range(_flags[flag]):
			child.remove_flag(flag)

#endregion
