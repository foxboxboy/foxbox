extends "res://tests/fox_test.gd"


## FoxAttributeRule is abstract, so tests need a concrete one.
class FlatRule extends FoxAttributeRule:
	var amount: float = 0.0

	func _init(p_id: StringName = &"", p_key: StringName = &"", p_amount: float = 0.0) -> void:
		super(p_id, p_key)
		amount = p_amount

	func apply_to(map: FoxAttributeMap) -> void:
		map.set_data(target_key, float(map.get_data(target_key, 0.0)) + amount)

	func remove_from(map: FoxAttributeMap) -> void:
		map.set_data(target_key, float(map.get_data(target_key, 0.0)) - amount)


func run() -> void:
	suite = "attribute_map"
	_data_storage()
	_groups()
	_flags_stack()
	_rules_apply_and_reverse()
	_local_add_rule_ignores_can_receive_rules()
	_inheritance_respects_can_receive_rules()
	_can_send_rules_stops_propagation()
	_late_joining_children_catch_up()


func _new_map() -> FoxAttributeMap:
	return track(FoxAttributeMap.new()) as FoxAttributeMap


func _data_storage() -> void:
	case("data")
	var m := _new_map()
	var added := [0]
	var replaced := [0]
	var removed := [0]
	m.data_added.connect(func(_k: StringName, _v: Variant) -> void: added[0] += 1)
	m.data_replaced.connect(func(_k: StringName, _v: Variant) -> void: replaced[0] += 1)
	m.data_removed.connect(func(_k: StringName, _v: Variant) -> void: removed[0] += 1)

	check(not m.has_data(&"hp"), "unknown key is absent")
	eq(m.get_data(&"hp", 99), 99, "get_data falls back to the default")

	m.set_data(&"hp", 50)
	eq(m.get_data(&"hp"), 50, "stored value comes back")
	eq(added[0], 1, "a new key emits data_added")
	eq(replaced[0], 0, "a new key does not emit data_replaced")

	m.set_data(&"hp", 75)
	eq(m.get_data(&"hp"), 75, "value was overwritten")
	eq(added[0], 1, "overwriting does not emit data_added again")
	eq(replaced[0], 1, "overwriting emits data_replaced")

	m.erase_data(&"hp")
	check(not m.has_data(&"hp"), "erased key is gone")
	eq(removed[0], 1, "erasing emits data_removed")

	m.erase_data(&"hp")
	eq(removed[0], 1, "erasing a missing key is silent")


func _groups() -> void:
	case("groups")
	var m := _new_map()
	m.set_data(&"speed", 5.0)
	m.set_data(&"accel", 2.0)

	m.add_data_to_group(&"speed", &"movement")
	m.add_data_to_group(&"accel", &"movement")
	check(m.has_group(&"movement"), "group was created implicitly")
	eq(m.get_data_in_group(&"movement").size(), 2, "group returns both values")

	m.add_data_to_group(&"speed", &"movement")
	eq(m.get_data_in_group(&"movement").size(), 2, "adding the same key twice does not duplicate")

	m.erase_data_from_group(&"speed", &"movement")
	eq(m.get_data_in_group(&"movement").size(), 1, "removing from a group shrinks it")

	eq(m.get_data_in_group(&"nope").size(), 0, "unknown group returns an empty array")

	# erasing the data itself should also purge it from every group
	m.add_data_to_group(&"speed", &"movement")
	m.erase_data(&"speed")
	eq(m.get_data_in_group(&"movement").size(), 1, "erasing data removes it from its groups")

	check(m.erase_group(&"movement"), "erasing an existing group reports success")
	check(not m.erase_group(&"movement"), "erasing it twice reports failure")


func _flags_stack() -> void:
	case("flags are stacked, not boolean")
	var m := _new_map()
	var added := [0]
	var removed := [0]
	m.flag_added.connect(func(_f: StringName) -> void: added[0] += 1)
	m.flag_removed.connect(func(_f: StringName) -> void: removed[0] += 1)

	check(not m.has_flag(&"slowed"), "unknown flag is absent")
	eq(m.get_flag_stacks(&"slowed"), 0, "unknown flag has zero stacks")

	m.increment_flag(&"slowed")
	check(m.has_flag(&"slowed"), "flag present after one increment")
	eq(added[0], 1, "flag_added fires on the first stack only")

	m.increment_flag(&"slowed")
	eq(m.get_flag_stacks(&"slowed"), 2, "second increment stacks")
	eq(added[0], 1, "flag_added does not fire again")

	m.decrement_flag(&"slowed")
	check(m.has_flag(&"slowed"), "one decrement of two leaves the flag set")
	eq(removed[0], 0, "flag_removed has not fired yet")

	m.decrement_flag(&"slowed")
	check(not m.has_flag(&"slowed"), "the last decrement clears it")
	eq(removed[0], 1, "flag_removed fires once")

	m.decrement_flag(&"slowed")
	eq(removed[0], 1, "decrementing below zero is silent")

	m.increment_flag(&"a")
	m.increment_flag(&"a")
	m.erase_flag(&"a")
	check(not m.has_flag(&"a"), "erase_flag drops every stack at once")

	m.increment_flag(&"x")
	m.increment_flag(&"y")
	m.clear_all_flags()
	check(not m.has_flag(&"x") and not m.has_flag(&"y"), "clear_all_flags empties everything")


func _rules_apply_and_reverse() -> void:
	case("rules")
	var m := _new_map()
	m.set_data(&"speed", 10.0)

	var rule := FlatRule.new(&"haste", &"speed", 5.0)
	m.add_rule(rule)
	almost(float(m.get_data(&"speed")), 15.0, "adding a rule applies it")
	eq(m.get_active_rules().size(), 1, "rule is tracked")

	m.add_rule(rule)
	eq(m.get_active_rules().size(), 1, "the same rule instance is not added twice")
	almost(float(m.get_data(&"speed")), 15.0, "and is not applied twice")

	m.remove_rule(&"haste")
	almost(float(m.get_data(&"speed")), 10.0, "removing a rule reverses it")
	eq(m.get_active_rules().size(), 0, "rule is untracked")

	m.remove_rule(&"nonexistent")
	almost(float(m.get_data(&"speed")), 10.0, "removing an unknown rule changes nothing")


## Regression: the can_receive_rules guard sat at the top of add_rule and fired for every
## caller, so a direct local call silently did nothing. The flag is only about inheritance.
func _local_add_rule_ignores_can_receive_rules() -> void:
	case("can_receive_rules does not block local calls")
	var m := _new_map()
	m.can_receive_rules = false
	m.set_data(&"speed", 10.0)

	m.add_rule(FlatRule.new(&"local", &"speed", 5.0))
	almost(float(m.get_data(&"speed")), 15.0, "a rule added directly still applies")
	eq(m.get_active_rules().size(), 1, "and is still tracked")


func _inheritance_respects_can_receive_rules() -> void:
	case("can_receive_rules blocks inherited rules")

	# entity -> [parent map, sub -> [child map]]
	var entity := track(Node.new())
	var parent_map := FoxAttributeMap.new()
	entity.add_child(parent_map)
	var sub := Node.new()
	entity.add_child(sub)
	var child_map := FoxAttributeMap.new()
	child_map.can_receive_rules = false
	sub.add_child(child_map)

	parent_map.set_data(&"speed", 10.0)
	child_map.set_data(&"speed", 10.0)

	parent_map.add_rule(FlatRule.new(&"aura", &"speed", 5.0))

	almost(float(parent_map.get_data(&"speed")), 15.0, "the parent applies its own rule")
	almost(float(child_map.get_data(&"speed")), 10.0, "the opted-out child ignores the inherited rule")
	eq(child_map.get_active_rules().size(), 0, "and does not track it")

	case("an opted-in child does inherit")
	var entity2 := track(Node.new())
	var pm := FoxAttributeMap.new()
	entity2.add_child(pm)
	var sub2 := Node.new()
	entity2.add_child(sub2)
	var cm := FoxAttributeMap.new()
	sub2.add_child(cm)

	pm.set_data(&"speed", 10.0)
	cm.set_data(&"speed", 10.0)
	pm.add_rule(FlatRule.new(&"aura2", &"speed", 5.0))

	almost(float(cm.get_data(&"speed")), 15.0, "the child receives the parent's rule")
	eq(cm.get_active_rules().size(), 1, "and tracks it")

	pm.remove_rule(&"aura2")
	almost(float(cm.get_data(&"speed")), 10.0, "removing on the parent reverses it on the child")


func _can_send_rules_stops_propagation() -> void:
	case("can_send_rules")
	var entity := track(Node.new())
	var pm := FoxAttributeMap.new()
	pm.can_send_rules = false
	entity.add_child(pm)
	var sub := Node.new()
	entity.add_child(sub)
	var cm := FoxAttributeMap.new()
	sub.add_child(cm)

	pm.set_data(&"speed", 10.0)
	cm.set_data(&"speed", 10.0)
	pm.add_rule(FlatRule.new(&"selfish", &"speed", 5.0))

	almost(float(pm.get_data(&"speed")), 15.0, "the parent still applies it locally")
	almost(float(cm.get_data(&"speed")), 10.0, "nothing propagated down")


func _late_joining_children_catch_up() -> void:
	case("late joining children")
	var entity := track(Node.new())
	var pm := FoxAttributeMap.new()
	entity.add_child(pm)

	pm.set_data(&"speed", 10.0)
	pm.add_rule(FlatRule.new(&"early", &"speed", 5.0))
	pm.increment_flag(&"blessed")
	pm.increment_flag(&"blessed")

	# child arrives after the rule and flags already exist
	var sub := Node.new()
	entity.add_child(sub)
	var cm := FoxAttributeMap.new()
	cm.set_data(&"speed", 100.0)
	sub.add_child(cm)

	almost(float(cm.get_data(&"speed")), 105.0, "the existing rule was applied on join")
	eq(cm.get_flag_stacks(&"blessed"), 2, "existing flag stacks were copied across")
